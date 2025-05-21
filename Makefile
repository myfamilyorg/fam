CC      = clang
CFLAGS  = -fPIC \
	 -std=c89 \
	 -pedantic \
	 -Wall \
	 -Wextra \
	 -O3 \
	 -Wno-variadic-macros \
	 -Wno-long-long \
	 -fno-stack-protector \
	 -fno-builtin \
	 -DSTATIC=static
LDFLAGS = -shared

# Directories
OBJDIR  = .obj
LIBDIR  = lib
BINDIR  = .
INCLDIR = src/include
SRCDIR  = src

SOURCES = $(wildcard $(SRCDIR)/core/*.c)
OBJECTS = $(patsubst $(SRCDIR)/core/%.c,$(OBJDIR)/%.o,$(SOURCES))

# Default target
all: $(LIBDIR)/libfam.so

$(OBJDIR)/%.o: $(SRCDIR)/core/%.c $(INCLDIR)/%.h
	$(CC) -I$(INCLDIR) $(CFLAGS) -c $< -o $@

$(LIBDIR)/libfam.so: $(OBJECTS) | $(LIBDIR)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)

# Clean up
clean:
	rm -fr $(OBJDIR)/*.o $(LIBDIR)/*.so

# Phony targets
.PHONY: all test bench clean
