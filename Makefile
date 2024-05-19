PROGRAM=playvgm
MODULES=main mmu vgm irq pgx
DEPDIR=.deps

PGXFILE=$(addsuffix .pgx,$(PROGRAM))
LABELS=$(addsuffix .lbl,$(PROGRAM))
LISTINGS=$(addsuffix .lst,$(MODULES))
MAPFILE=$(addsuffix .map,$(PROGRAM))
OBJECTS=$(addsuffix .o,$(MODULES))
DEPS=$(addprefix $(DEPDIR)/,$(addsuffix .d,$(MODULES)))

all: $(DEPS) $(PGXFILE)

$(PGXFILE): playvgm.cfg $(OBJECTS)
	ld65 -o $@ -Ln $(LABELS) -m $(MAPFILE) -vm -C $^

$(DEPDIR)/%.d: %.s
	@mkdir -p $(DEPDIR)
	@python util/deps.py -o $@ $<

%.o %.lst: %.s
	ca65 --cpu 65c02 -o $@ -l $(addsuffix .lst,$(basename $@)) $<

clean:
	rm -f $(PGXFILE) $(LABELS) $(LISTINGS) $(MAPFILE) $(OBJECTS)

distclean: clean
	rm -rf $(DEPDIR)

.PHONY: all clean distclean

-include $(DEPS)
