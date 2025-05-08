#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tomlc17.h"

static void error(const char *msg, const char *msg1) {
	fprintf(stderr, "ERROR: %s%s\n", msg, msg1 ? msg1 : "");
	exit(-1);
}

#define PATH_MAX 2048

int main(int argc, char **argv) {
	if (argc != 4) {
		error("Usage: lock [lock_file] [key] [hash_to_set]", 0);
	}

	if (strlen(argv[1]) > PATH_MAX - 10) {
		error("lock file path too long - ", argv[1]);
	}

	FILE *fp = fopen(argv[1], "r");
	if (!fp) error("cannot open specified file - ", argv[1]);

	toml_result_t result = toml_parse_file(fp);
	fclose(fp);  // done with the file handle

	// Check for parse error
	if (!result.ok) {
		error(result.errmsg, 0);
	}

	toml_datum_t deps = toml_table_find(result.toptab, "deps");

	const char *res_value = NULL;

	if (deps.type == TOML_TABLE) {
		for (int i = 0; i < deps.u.tab.size; i++) {
			const char *key = deps.u.tab.key[i];
			const toml_datum_t value = deps.u.tab.value[i];

			if (value.type != TOML_TABLE) {
				error("ERROR:  not a table: ", key);
			}

			if (value.u.tab.size != 1) {
				error("ERROR: Must be exactly one k/v: ", key);
			}

			const char *subkey = value.u.tab.key[0];
			toml_datum_t subvalue = value.u.tab.value[0];

			if (subvalue.type == TOML_STRING && subvalue.u.s) {
				const char *hash = subvalue.u.s;
				// printf("%s -> [%s, %s]\n", key, subkey,
				// hash);
				if (!strcmp(key, argv[2])) {
					res_value = hash;
				}
			} else {
				error("Not a string: ", subkey);
			}
		}
	}

	if (res_value) {
		printf("%s\n", res_value);
	} else {
		char fname[PATH_MAX] = {0};
		strcpy(fname, argv[1]);
		strcat(fname, ".tmp");
		FILE *fp = fopen(fname, "w");
		if (!fp) error("cannot open specified file - ", argv[1]);

		if (fprintf(fp, "[deps]\n") < 0) {
			error("1error writing to file - ", argv[1]);
		}

		if (deps.type == TOML_TABLE) {
			for (int i = 0; i < deps.u.tab.size; i++) {
				const char *key = deps.u.tab.key[i];
				const toml_datum_t value = deps.u.tab.value[i];

				const char *subkey = value.u.tab.key[0];
				toml_datum_t subvalue = value.u.tab.value[0];
				const char *hash = subvalue.u.s;

				if (fprintf(fp, "\t%s = { %s = \"%s\" }\n", key,
					    subkey, hash) < 0)
					error("2error writing to file - ",
					      argv[1]);
			}
		}
		if (fprintf(fp, "\t%s = { rev = \"%s\" }\n", argv[2], argv[3]) <
		    0)
			error("3error writing to file - ", argv[1]);
		if (fclose(fp) != 0)
			error("4error writing to file - ", argv[1]);
		rename(fname, argv[1]);
	}

	return 0;
}
