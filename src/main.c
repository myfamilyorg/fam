#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

struct Obj {
	char *name;
	char *public;
	char **headers;
	int num_headers;
	int headers_capacity;
};

struct Project {
	char *name;
	struct Obj *objs;
	int num_objs;
	int objs_capacity;
};

char *trim(char *str) {
	while (isspace((unsigned char)*str)) str++;
	if (*str == 0) return str;
	char *end = str + strlen(str) - 1;
	while (end > str && isspace((unsigned char)*end)) end--;
	end[1] = 0;
	return str;
}

void add_header(struct Obj *obj, const char *header) {
	if (obj->num_headers >= obj->headers_capacity) {
		obj->headers_capacity += 10;
		obj->headers = realloc(obj->headers,
				       obj->headers_capacity * sizeof(char *));
	}
	obj->headers[obj->num_headers++] = strdup(header);
}

static int strcmp_func(const void *a, const void *b) {
	return strcmp(*(const char **)a, *(const char **)b);
}

int main(int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr, "Usage: %s <toml_file>\n", argv[0]);
		return 1;
	}

	FILE *fp = fopen(argv[1], "r");
	if (!fp) {
		perror("fopen");
		return 1;
	}

	struct Project proj = {0};
	proj.objs_capacity = 5;
	proj.objs = malloc(proj.objs_capacity * sizeof(struct Obj));

	int in_project = 0;
	int in_obj = 0;
	int in_headers = 0;
	struct Obj current_obj = {0};

	char line[1024];
	while (fgets(line, sizeof(line), fp)) {
		char *tline = trim(line);
		if (!*tline || *tline == '#') continue;

		if (tline[0] == '[') {
			if (in_headers) {
				in_headers = 0;
			}
			if (in_obj) {
				if (proj.num_objs >= proj.objs_capacity) {
					proj.objs_capacity += 5;
					proj.objs = realloc(
					    proj.objs, proj.objs_capacity *
							   sizeof(struct Obj));
				}
				proj.objs[proj.num_objs++] = current_obj;
				in_obj = 0;
			}
			if (strcmp(tline, "[project]") == 0) {
				in_project = 1;
			} else if (strcmp(tline, "[deps]") == 0) {
				in_project = 0;
			}
			continue;
		}

		if (!in_project) continue;

		if (in_headers) {
			if (strcmp(tline, "}") == 0) {
				in_headers = 0;
				continue;
			}
			char *val_start = trim(tline);
			if (*val_start == '"') val_start++;
			char *val_end = strchr(val_start, '"');
			if (val_end) *val_end = 0;
			add_header(&current_obj, val_start);
			continue;
		}

		char *eq = strchr(tline, '=');
		if (!eq) {
			if (strcmp(tline, "}") == 0) {
				if (in_obj) {
					if (proj.num_objs >=
					    proj.objs_capacity) {
						proj.objs_capacity += 5;
						proj.objs = realloc(
						    proj.objs,
						    proj.objs_capacity *
							sizeof(struct Obj));
					}
					proj.objs[proj.num_objs++] =
					    current_obj;
					in_obj = 0;
				}
			}
			continue;
		}
		*eq = 0;
		char *key = trim(tline);
		char *val = trim(eq + 1);

		if (in_obj) {
			if (strcmp(key, "name") == 0) {
				if (*val == '"') val++;
				char *endq = strchr(val, '"');
				if (endq) *endq = 0;
				current_obj.name = strdup(val);
			} else if (strcmp(key, "public") == 0) {
				if (*val == '"') val++;
				char *endq = strchr(val, '"');
				if (endq) *endq = 0;
				current_obj.public = strdup(val);
			} else if (strcmp(key, "headers") == 0) {
				if (val[0] != '{') {
					fprintf(stderr,
						"Parse error: expected {\n");
					return 1;
				}
				char *array_start = val + 1;
				char *array_end = strstr(val, "}");
				if (array_end) {
					*array_end = 0;
					array_start = trim(array_start);
					char *token = strtok(array_start, ",");
					while (token) {
						char *t = trim(token);
						if (*t == '"') t++;
						char *e = strchr(t, '"');
						if (e) *e = 0;
						add_header(&current_obj, t);
						token = strtok(NULL, ",");
					}
				} else {
					in_headers = 1;
				}
			}
		} else {
			if (strcmp(key, "name") == 0) {
				if (*val == '"') val++;
				char *endq = strchr(val, '"');
				if (endq) *endq = 0;
				proj.name = strdup(val);
			} else if (strcmp(key, "obj") == 0) {
				if (val[0] != '{') {
					fprintf(stderr,
						"Parse error: expected {\n");
					return 1;
				}
				in_obj = 1;
				memset(&current_obj, 0, sizeof(current_obj));
				current_obj.headers_capacity = 10;
				current_obj.headers =
				    malloc(current_obj.headers_capacity *
					   sizeof(char *));
			}
		}
	}

	if (in_obj) {
		if (proj.num_objs >= proj.objs_capacity) {
			proj.objs_capacity += 5;
			proj.objs = realloc(
			    proj.objs, proj.objs_capacity * sizeof(struct Obj));
		}
		proj.objs[proj.num_objs++] = current_obj;
	}

	fclose(fp);

	const char *cc = "gcc";
	const char *cflags =
	    "-fPIC -Wno-builtin-declaration-mismatch -fvisibility=hidden "
	    "-DSTATIC=static";
	const char *ldflags =
	    "-shared -nostdlib -ffreestanding -fvisibility=hidden";

	system("rm -rf ./target/objs/* ./target/lib/*");
	system("mkdir -p ./target/objs ./target/lib");

	for (int i = 0; i < proj.num_objs; i++) {
		struct Obj o = proj.objs[i];
		char cmd[8192] = {0};
		snprintf(cmd, sizeof(cmd), "%s %s", cc, cflags);

		const char *known_headers[] = {"types.H", "errno.H",
					       "syscall.H", "misc.H", "init.H"};
		int num_known = 5;
		for (int k = 0; k < num_known; k++) {
			for (int j = 0; j < o.num_headers; j++) {
				if (strcmp(o.headers[j], known_headers[k]) ==
				    0) {
					char include[256];
					snprintf(include, sizeof(include),
						 " -include src/%s",
						 known_headers[k]);
					strcat(cmd, include);
					break;
				}
			}
		}

		char oname[256];
		strcpy(oname, o.name);
		char *dot = strrchr(oname, '.');
		if (dot && strcmp(dot, ".c") == 0) {
			*dot = 0;
		}
		char src[256], obj[256];
		snprintf(src, sizeof(src), " -c src/%s", o.name);
		snprintf(obj, sizeof(obj), " -o ./target/objs/%s.o", oname);
		strcat(cmd, src);
		strcat(cmd, obj);

		printf("%s\n", cmd);
		if (system(cmd) != 0) {
			fprintf(stderr, "Compilation failed for %s\n", o.name);
			return 1;
		}
	}

	// Linking with sorted obj files
	char **obj_paths = malloc(proj.num_objs * sizeof(char *));
	for (int i = 0; i < proj.num_objs; i++) {
		char oname[256];
		strcpy(oname, proj.objs[i].name);
		char *dot = strrchr(oname, '.');
		if (dot && strcmp(dot, ".c") == 0) {
			*dot = 0;
		}
		obj_paths[i] = malloc(256);
		snprintf(obj_paths[i], 256, "./target/objs/%s.o", oname);
	}
	qsort(obj_paths, proj.num_objs, sizeof(char *), strcmp_func);

	char linkcmd[4096] = {0};
	snprintf(linkcmd, sizeof(linkcmd), "%s %s -o ./target/lib/lib%s.so", cc,
		 ldflags, proj.name);
	for (int i = 0; i < proj.num_objs; i++) {
		strcat(linkcmd, " ");
		strcat(linkcmd, obj_paths[i]);
	}
	printf("%s\n", linkcmd);
	if (system(linkcmd) != 0) {
		fprintf(stderr, "Linking failed\n");
		return 1;
	}

	// Free obj_paths
	for (int i = 0; i < proj.num_objs; i++) {
		free(obj_paths[i]);
	}
	free(obj_paths);

	// Free memory
	free(proj.name);
	for (int i = 0; i < proj.num_objs; i++) {
		free(proj.objs[i].name);
		free(proj.objs[i].public);
		for (int j = 0; j < proj.objs[i].num_headers; j++) {
			free(proj.objs[i].headers[j]);
		}
		free(proj.objs[i].headers);
	}
	free(proj.objs);

	return 0;
}
