.PHONY: clean

CXXFLAGS = `pkg-config pficommon --libs --cflags`
LIBS = -lmsgpack -ljubatus_mpio -ljubatus_msgpack-rpc

PROGRAMS = gender gender-robust gender-robust-clean

all: $(PROGRAMS)

gender: gender.cpp
	g++ -O2 -o $@ $< $(CXXFLAGS) $(LIBS)

gender-robust: gender-robust.cpp
	g++ -O2 -o $@ $< $(CXXFLAGS) $(LIBS)

gender-robust-clean: gender-robust-clean.cpp
	g++ -O2 -o $@ $< $(CXXFLAGS) $(LIBS)

clean:
	rm -f *.o $(PROGRAMS)

