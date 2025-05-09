#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tomlc17.h"

#define MAX_OUT_SIZE (1024 * 512)

void error(const char *file, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);

	if (file != NULL) {
		char *canonical_path = realpath(file, NULL);
		if (canonical_path == NULL) {
			fprintf(stderr, "File [%s] contained errors: ", file);
			free(canonical_path);
		} else {
			fprintf(stderr,
				"File [%s] contained errors: ", canonical_path);
		}
	}
	vfprintf(stderr, fmt, args);
	va_end(args);
	fprintf(stderr, ".\n");
	exit(-1);
}

void parse_deps(const char *file, toml_result_t result, char *buf, int offset) {
	toml_datum_t deps = toml_table_find(result.toptab, "deps");
	if (deps.type != TOML_TABLE) {
		error(file, "[deps] table not found.");
	}

	int ret = snprintf(buf + offset, MAX_OUT_SIZE - offset, " %d",
			   deps.u.tab.size);
	if (ret < 0) error(file, "file was too big!");
	offset += ret;

	for (int i = 0; i < deps.u.tab.size; i++) {
		const char *key = deps.u.tab.key[i];
		const toml_datum_t value = deps.u.tab.value[i];

		if (value.type != TOML_TABLE) {
			error(file,
			      "Invalid format found near depdendency %s. "
			      "Expected "
			      "format: %s = { [git | path] = \"<location>\" }",
			      key, key);
		}

		if (value.u.tab.size < 1 || value.u.tab.size > 2) {
			error(file,
			      "Invalid format found near depdendency %s. "
			      "Expected "
			      "format: %s = { [git | path] = \"<location>\" }",
			      key, key);
		}
		const char *dep_type = value.u.tab.key[0];
		const toml_datum_t dep_location = value.u.tab.value[0];
		if (dep_location.type != TOML_STRING) {
			error(file,
			      "Invalid format found near depdendency %s. "
			      "Expected "
			      "format: %s = { [git | path] = \"<location>\" }",
			      key, key);
		}
		const char *dep_location_s = dep_location.u.s;

		if (!strcmp(dep_type, "git")) {
			if (value.u.tab.size == 1) {
				int ret = snprintf(
				    buf + offset, MAX_OUT_SIZE - offset,
				    " %s git %s", key, dep_location_s);
				if (ret < 0) error(file, "file was too big");
				offset += ret;
			} else {
				const char *tag_type = value.u.tab.key[1];
				if (strcmp(tag_type, "tag")) {
					error(file,
					      "Invalid format found near "
					      "depdendency %s. "
					      "second attribute in depedency "
					      "must be 'tag'. Found '%s'.",
					      key, tag_type);
				}
				const toml_datum_t tag = value.u.tab.value[1];
				if (tag.type != TOML_STRING) {
					error(file,
					      "Invalid format found near "
					      "depdendency %s. "
					      "second attribute in depedency "
					      "must be of the form "
					      "'tag=\"<tag>\".",
					      key);
				}
				const char *tag_s = tag.u.s;
				int ret = snprintf(buf + offset,
						   MAX_OUT_SIZE - offset,
						   " %s git %s#%s", key,
						   dep_location_s, tag_s);
				if (ret < 0) error(file, "file was too big");
				offset += ret;
			}
		} else if (!strcmp(dep_type, "path")) {
			if (value.u.tab.size != 1) {
				error(
				    file,
				    "Invalid format found near depdendency %s. "
				    "path can only have a single value in the "
				    "dep table.",
				    key);
			}
			int ret = snprintf(buf + offset, MAX_OUT_SIZE - offset,
					   " %s path %s", key, dep_location_s);
			if (ret < 0) error(file, "file was too big");
			offset += ret;
		} else {
			error(file,
			      "Invalid format found near depdendency %s. "
			      "Expected "
			      "format: %s = { [git | path] = \"<location>\" }",
			      key, key);
		}
	}
}

void parse_toml(char *file) {
	char buf[MAX_OUT_SIZE] = {0};
	int offset = 0;

	FILE *fp = fopen(file, "r");
	if (!fp) error(file, "fopen");
	toml_result_t result = toml_parse_file(fp);
	fclose(fp);

	if (!result.ok)
		error(file, "toml parse error. message: %s", result.errmsg);

	toml_datum_t crate = toml_table_find(result.toptab, "crate");
	if (crate.type != TOML_TABLE) {
		error(file, "file did not have a [crate] table");
	}

	toml_datum_t bin = toml_table_find(crate, "bin");
	toml_datum_t lib = toml_table_find(crate, "lib");

	int count = 0;
	if (bin.type == TOML_STRING) count++;
	if (lib.type == TOML_STRING) count++;

	if (count != 1) {
		error(file,
		      "must include either a bin or lib value in its [crate] "
		      "table");
	} else if (bin.type == TOML_STRING) {
		if (strstr(bin.u.s, " ") != NULL) {
			error(file, "bin name cannot contain a space");
		}
		offset = snprintf(buf, sizeof(buf), "bin %s", bin.u.s);
	} else if (lib.type == TOML_STRING) {
		if (strstr(lib.u.s, " ") != NULL) {
			error(file, "lib name cannot contain a space");
		}
		offset = snprintf(buf, sizeof(buf), "lib %s", lib.u.s);
	} else {
		error(file, "unrecognized value for bin or lib");
	}

	parse_deps(file, result, buf, offset);
	fprintf(stdout, "%s\n", buf);
}

void parse_lock(char *file) {}

int main(int argc, char **argv) {
	if (argc != 3) {
		error(NULL,
		      "Usage: tomlparse [mode] [file]\n\
mode options: toml lock");
	}
	if (!strcmp(argv[1], "toml")) {
		parse_toml(argv[2]);
	} else if (!strcmp(argv[1], "lock")) {
		parse_lock(argv[2]);
	} else {
		error(NULL,
		      "Usage: tomlparse [mode] [file]\n\
mode options: toml lock");
	}

	return 0;
}
