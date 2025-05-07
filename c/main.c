/*
 * Parse the config file fam.toml:
 *
 * [crate]
 *     bin = "<binary_name>"
 *     or
 *     lib = "object_name>"
 *
 * [deps]
 *     mydep1 = { path = "../path/to/dep1" }
 *     mydep2 = { path = "../path/to/dep2" }
 *     mydep3 = { git = "https://github.com/cgilliard/mycrate" }
 *     ...
 *
 */
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "tomlc17.h"

static void error(const char *msg, const char *msg1) {
	fprintf(stderr, "ERROR: %s%s\n", msg, msg1 ? msg1 : "");
	exit(-1);
}

#define MAX_OUT_SIZE (1024 * 512)

int parse_deps(toml_result_t result, char *buf, int offset) {
	toml_datum_t deps = toml_table_find(result.toptab, "deps");
	if (deps.type != TOML_TABLE) {
		error("deps table not found!", 0);
	}
	int ret = snprintf(buf + offset, MAX_OUT_SIZE - offset, " %d",
			   deps.u.tab.size);
	if (ret < 0) error("file was too big!", 0);
	offset += ret;
	for (int i = 0; i < deps.u.tab.size; i++) {
		const char *key = deps.u.tab.key[i];
		const toml_datum_t value = deps.u.tab.value[i];

		if (value.type != TOML_TABLE) {
			error("ERROR: %s is not a table!", key);
		}

		for (int j = 0; j < value.u.tab.size; j++) {
			const char *subkey = value.u.tab.key[j];
			toml_datum_t subvalue = value.u.tab.value[j];

			if (strcmp(subkey, "git") && strcmp(subkey, "path") &&
			    strcmp(subkey, "rev")) {
				error(
				    "only subkeys of 'git', 'rev', and 'path' "
				    "are "
				    "supported",
				    0);
			}
			if (!strcmp(subkey, "git") && value.u.tab.size == 1) {
				error(
				    "Error: git requires 'rev' to be specified "
				    "as well",
				    0);
			}

			if (!strcmp(subkey, "rev") && j == 0) {
				error("rev must be the second subkey", 0);
			}
			if (j != 0 && strcmp(subkey, "rev")) {
				error(
				    "invalid dependency only 'rev' can come "
				    "after 'git'",
				    0);
			}
			if (j != 0 && strcmp(value.u.tab.key[0], "git")) {
				error("only type 'git' allows additional entry",
				      0);
			}
			if (j == 2) {
				error(
				    "too many additional entries for this "
				    "dependency",
				    0);
			}

			if (subvalue.type == TOML_STRING && subvalue.u.s) {
				if (strstr(subvalue.u.s, " ") != NULL) {
					error(
					    "subvalue cannot contain a "
					    "space",
					    0);
				}
				if (j == 0) {
					int ret = snprintf(
					    buf + offset, MAX_OUT_SIZE - offset,
					    " %s %s %s", key, subkey,
					    subvalue.u.s);
					if (ret < 0)
						error("file was too big!", 0);
					offset += ret;
				} else {
					// rev
					int ret = snprintf(
					    buf + offset, MAX_OUT_SIZE - offset,
					    "#%s", subvalue.u.s);
					if (ret < 0)
						error("file was too big!", 0);
					offset += ret;
				}
			} else {
				error("not a string\n", subkey);
			}
		}
	}
	return 0;
}

int main(int argc, char **argv) {
	char buf[MAX_OUT_SIZE];
	int offset = 0;

	// Open the toml file
	FILE *fp;
	if (argc == 1) {
		fp = fopen("fam.toml", "r");
		if (!fp) error("cannot open fam.toml - ", strerror(errno));
	} else if (argc == 2) {
		fp = fopen(argv[1], "r");
		if (!fp) error("cannot open specified file - ", argv[1]);
	} else
		error("either 0 or 1 arguments must be specified!", 0);

	// Parse the toml file
	toml_result_t result = toml_parse_file(fp);
	fclose(fp);  // done with the file handle

	// Check for parse error
	if (!result.ok) {
		error(result.errmsg, 0);
	}

	// Extract values
	toml_datum_t crate = toml_table_find(result.toptab, "crate");
	if (crate.type != TOML_TABLE) {
		error("crate table not found!", 0);
	}

	toml_datum_t bin = toml_table_find(crate, "bin");
	toml_datum_t lib = toml_table_find(crate, "lib");
	toml_datum_t macro = toml_table_find(crate, "proc-macro");

	int count = 0;
	if (bin.type == TOML_STRING) count++;
	if (lib.type == TOML_STRING) count++;
	if (macro.type == TOML_STRING) count++;

	if (count == 0) {
		error("'lib', 'macro', or 'bin' must be specified!", 0);
	} else if (count > 1) {
		error(
		    "only one of either 'lib', 'macro', or 'bin' may be "
		    "specified!",
		    0);
	} else if (bin.type == TOML_STRING) {
		if (strstr(bin.u.s, " ") != NULL) {
			error("bin cannot contain a space", 0);
		}

		offset = snprintf(buf, sizeof(buf), "bin %s", bin.u.s);
	} else if (macro.type == TOML_STRING) {
		if (strstr(macro.u.s, " ") != NULL) {
			error("proc-macro cannot contain a space", 0);
		}
		offset = snprintf(buf, sizeof(buf), "proc-macro %s", macro.u.s);
	} else {
		if (strstr(lib.u.s, " ") != NULL) {
			error("lib cannot contain a space", 0);
		}
		offset = snprintf(buf, sizeof(buf), "lib %s", lib.u.s);
	}

	parse_deps(result, buf, offset);

	printf("%s\n", buf);

	// Done!
	toml_free(result);
	return 0;
}
