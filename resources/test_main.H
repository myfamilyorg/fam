#ifndef _TEST_H
#define _TEST_H

int main(int argc, char *argv[], char *envp[]);

#ifdef __aarch64__
__asm__(
    ".section .text\n"
    ".global _start\n"
    "_start:\n"
    "    ldr x0, [sp]\n"
    "    add x1, sp, #8\n"
    "    add x3, x0, #1\n"
    "    lsl x3, x3, #3\n"
    "    add x2, x1, x3\n"
    "    sub sp, sp, x3\n"
    "    bl main\n"
    "    mov x8, #93\n"
    "    svc #0\n");
#endif /* __aarch64__ */

int main(int argc __attribute__((unused)), char **argv __attribute__((unused)),
	 char **envp) {
	return 4;
}
#endif /* _TEST_H */
