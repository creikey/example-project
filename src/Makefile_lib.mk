.PHONY: all clean debug debug-test linux windows mac ios android test update

include Settings.mk

PLATERR=$(PLATERRPREFIX) $(PROJECTNAME)
SRC=$(filter-out main.c $(wildcard *.c))
SRC_TEST=$(SRC) + main.c
HEADERS=$(wildcard *.h)
LIBNAME=lib$(PROJECTNAME).a
TESTEXNAME=test_$(PROJECTNAME).out
OBJS=$(addprefix $(BUILDDIR)/, $(SRC:.c=.o))
OBJS_TEST=$(OBJS) + $(BUILDDIR)/main.o
EXPORTDIR=$(../..)/exported
CC=gcc
AR=ar

# pull in dependency info from existing .o files
-include $(OBJS_TEST:.o=.d)

# compile and generate dependency info
$(BUILDDIR)/%.o : %.c
	mkdir -p $(BUILDDIR)
	$(CC) -c $(CFLAGS) $< -o $@
	$(CC) -MM $(CFLAGS) $< > $*.d
	@cp -f $*.d $*.d.tmp
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp

all: update libs includedir $(LIBNAME)
	@echo "Exporting $(PROJECTNAME) v$(VERSION)..."
	cp -r $(PROJECTNAME) $(EXPORTDIR)
	cp $(LIBNAME) $(EXPORTDIR)

$(LIBNAME): $(OBJS)
	$(AR) rcs $(LIBNAME) $(OBJS)

includedir: $(HEADERS)
	@echo "Constructing include dir $(PROJECTNAME)..."
	rm -rf $(PROJECTNAME)
	mkdir $(PROJECTNAME)
	cp $(HEADERS) $(PROJECTNAME)

clean:
	-rm -f $(BUILDDIR)/*.o
	-rm -f $(BUILDDIR)/*.d
	-rm -f $(EXNAME)
	-rm -f $(TESTEXNAME)
	-rm -rf $(LIBNAME)

debug: CFLAGS += -g
debug: clean all

debug-test: CFLAGS += -g
debug-test: test

linux: CFLAGS += -DLINUX
linux: clean all

windows mac ios android:
	$(error $@ $(PLATERR))

test: CFLAGS += -D$(TESTMACRO)
test: clean
	$(CC) $(OBJS_TEST) $(CFLAGS) -o $(TESTEXNAME)

libs:
	@echo "Building libraries..."
	cd $(LIBDIR) && $(MAKE) library

update:
	git submodule init
	git submodule update
