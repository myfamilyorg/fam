#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

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

int need_compile(const char *obj_path, const char *src_path, char **headers,
		 int num_headers, const char *root_dir) {
	struct stat obj_stat;
	if (stat(obj_path, &obj_stat) != 0) return 1;  // no obj, compile
	time_t obj_mtime = obj_stat.st_mtime;

	struct stat src_stat;
	if (stat(src_path, &src_stat) != 0) {
		fprintf(stderr, "Missing source file: %s\n", src_path);
		return 1;
	}
	if (src_stat.st_mtime > obj_mtime) return 1;

	for (int j = 0; j < num_headers; j++) {
		char header_path[1024];
		snprintf(header_path, sizeof(header_path), "%s/src/%s",
			 root_dir, headers[j]);
		struct stat h_stat;
		if (stat(header_path, &h_stat) != 0) {
			fprintf(stderr, "Missing header file: %s\n",
				header_path);
			return 1;
		}
		if (h_stat.st_mtime > obj_mtime) return 1;
	}

	return 0;
}

int need_link(const char *lib_path, char **obj_paths, int num_objs) {
	struct stat lib_stat;
	if (stat(lib_path, &lib_stat) != 0) return 1;
	time_t lib_mtime = lib_stat.st_mtime;

	for (int i = 0; i < num_objs; i++) {
		struct stat o_stat;
		if (stat(obj_paths[i], &o_stat) != 0) return 1;
		if (o_stat.st_mtime > lib_mtime) return 1;
	}

	return 0;
}

int main(int argc, char *argv[]) {
	char *root_dir = ".";
	if (argc == 3 && strcmp(argv[1], "-d") == 0) {
		root_dir = argv[2];
	} else if (argc != 1) {
		fprintf(stderr, "Usage: %s [-d <directory>]\n", argv[0]);
		return 1;
	}

	char toml_path[1024];
	snprintf(toml_path, sizeof(toml_path), "%s/fam.toml", root_dir);

	FILE *fp = fopen(toml_path, "r");
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

	char mkdir_cmd[1024];
	snprintf(mkdir_cmd, sizeof(mkdir_cmd),
		 "mkdir -p %s/target/objs %s/target/lib", root_dir, root_dir);
	system(mkdir_cmd);

	char **obj_paths = malloc(proj.num_objs * sizeof(char *));
	for (int i = 0; i < proj.num_objs; i++) {
		struct Obj o = proj.objs[i];
		char oname[256];
		strcpy(oname, o.name);
		char *dot = strrchr(oname, '.');
		if (dot && strcmp(dot, ".c") == 0) {
			*dot = 0;
		}
		obj_paths[i] = malloc(1024);
		snprintf(obj_paths[i], 1024, "%s/target/objs/%s.o", root_dir,
			 oname);

		char src_path[1024];
		snprintf(src_path, sizeof(src_path), "%s/src/%s", root_dir,
			 o.name);

		if (!need_compile(obj_paths[i], src_path, o.headers,
				  o.num_headers, root_dir)) {
			continue;
		}

		char cmd[8192] = {0};
		snprintf(cmd, sizeof(cmd), "%s %s", cc, cflags);

		char *unique_headers[64] = {0};
		int unique_count = 0;
		for (int j = 0; j < o.num_headers; j++) {
			int is_unique = 1;
			for (int k = 0; k < unique_count; k++) {
				if (strcmp(unique_headers[k], o.headers[j]) ==
				    0) {
					is_unique = 0;
					break;
				}
			}
			if (is_unique) {
				unique_headers[unique_count++] = o.headers[j];
				char include[1024];
				snprintf(include, sizeof(include),
					 " -include %s/src/%s", root_dir,
					 o.headers[j]);
				strncat(cmd, include,
					sizeof(cmd) - strlen(cmd) - 1);
			}
		}

		char src[1024], obj[1024];
		snprintf(src, sizeof(src), " -c %s/src/%s", root_dir, o.name);
		snprintf(obj, sizeof(obj), " -o %s/target/objs/%s.o", root_dir,
			 oname);
		strncat(cmd, src, sizeof(cmd) - strlen(cmd) - 1);
		strncat(cmd, obj, sizeof(cmd) - strlen(cmd) - 1);

		printf("%s\n", cmd);
		if (system(cmd) != 0) {
			fprintf(stderr, "Compilation failed for %s\n", o.name);
			return 1;
		}
	}

	char lib_path[1024];
	snprintf(lib_path, sizeof(lib_path), "%s/target/lib/lib%s.so", root_dir,
		 proj.name);

	if (need_link(lib_path, obj_paths, proj.num_objs)) {
		qsort(obj_paths, proj.num_objs, sizeof(char *), strcmp_func);

		char linkcmd[8192] = {0};
		snprintf(linkcmd, sizeof(linkcmd), "%s %s -o %s", cc, ldflags,
			 lib_path);
		for (int i = 0; i < proj.num_objs; i++) {
			strncat(linkcmd, " ",
				sizeof(linkcmd) - strlen(linkcmd) - 1);
			strncat(linkcmd, obj_paths[i],
				sizeof(linkcmd) - strlen(linkcmd) - 1);
		}
		printf("%s\n", linkcmd);
		if (system(linkcmd) != 0) {
			fprintf(stderr, "Linking failed\n");
			return 1;
		}
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
		if (proj.objs[i].public) free(proj.objs[i].public);
		for (int j = 0; j < proj.objs[i].num_headers; j++) {
			free(proj.objs[i].headers[j]);
		}
		free(proj.objs[i].headers);
	}
	free(proj.objs);

	return 0;
}
