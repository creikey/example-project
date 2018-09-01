
.PHONY: all clean debug debug-test linux windows mac ios android test update

include Settings.mk

PLATERR=$(PLATERRPREFIX) $(PROJECTNAME)
SRC=$(wildcard *.c)
HEADERS=$(wildcard *.h)
EXNAME=$(PROJECTNAME).out
TESTEXNAME=test_$(EXNAME)
OBJS=$(addprefix $(BUILDDIR)/, $(SRC:.c=.o))
CC=gcc

# pull in dependency info from existing .o files
-include $(OBJS:.o=.d)


# compile and generate dependency info
$(BUILDDIR)/%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@
	$(CC) -MM $(CFLAGS) $< > $*.d
	@cp -f $*.d $*.d.tmp
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp

all: update libs $(OBJS)
	mkdir -p $(BUILDDIR)
	@echo "Building $(PROJECTNAME) v$(VERSION)..."
	$(CC) $(OBJS) $(CFLAGS) -o $(EXNAME)

clean:
	-rm -f $(BUILDDIR)/*.o
	-rm -f $(BUILDDIR)/*.d
	-rm -f $(EXNAME)
	-rm -f $(TESTEXNAME)

debug: CFLAGS += -g
debug: clean all

debug-test: CFLAGS += -g
debug-test: test


linux: CFLAGS += -DLINUX
linux: clean all

windows mac ios android:
	$(error $@ $(PLATERR))

test: CFLAGS += -D$(TESTMACRO)
test: EXNAME = TESTEXNAME
test: clean all

libs:
	@echo "Building libraries..."
	cd $(LIBDIR) && $(MAKE) executable

update:
	git submodule init
	git submodule update
