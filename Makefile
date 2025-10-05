CC := gcc

CFLAGS := $(shell pkg-config sdl2 --cflags) -fPIE -I include/ -I include/lib/quarklib/	

SRCDIR := src/
OBJDIR := build/obj/
LIBDIR := lib/

NAME := garchomp

SFILES := c
OFILES := o

LIBS := -lSDL2 -lOpenCL -lm

SOURCES := $(shell find $(SRCDIR) -name "*.$(SFILES)")
OBJECTS := $(patsubst $(SRCDIR)%.$(SFILES), $(OBJDIR)%.$(OFILES), $(SOURCES))

all: directories $(NAME)

directories:
	mkdir -p $(OBJDIR)
	mkdir -p $(OBJDIR)lib/quarklib
	mv $(NAME)_backup $(NAME)_backup1
	mv $(NAME) $(NAME)_backup

$(NAME): $(OBJECTS)
	$(CC) $^ $(LIBS) -o $@
$(OBJDIR)%$(OFILES): $(SRCDIR)%$(SFILES)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	mv $(NAME)_backup $(NAME)_backup1
	mv $(NAME) $(NAME)_backup
	rm -rf $(OBJDIR)		