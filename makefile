export builddir=$(abspath ./build)
export prefix=$(abspath ./install)
C=gcc
CXX=g++
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
ARCH := $(shell getconf LONG_BIT)
SHARED_LIB_EXT:=.so
INCLUDE_ARCHIVES_START = -Wl,-whole-archive # linking options, we prefer our generated shared object will be self-contained.
INCLUDE_ARCHIVES_END = -Wl,-no-whole-archive 
SHARED_LIB_OPT:=-shared

export uname_S
export ARCH
export SHARED_LIB_EXT
export INCLUDE_ARCHIVES_START
export INCLUDE_ARCHIVES_END
export SHARED_LIB_OPT
export exec_prefix=$(prefix)
export includedir=$(prefix)/include
export bindir=$(exec_prefix)/bin
export libdir=$(prefix)/lib

SLib           = libscapi.a
CPP_FILES     := $(wildcard src/*/*.cpp)
C_FILES     := $(wildcard src/*/*.c)
OBJ_FILES     := $(patsubst src/%.cpp,obj/%.o,$(CPP_FILES))
OUT_DIR        = obj obj/mid_layer obj/comm obj/infra obj/interactive_mid_protocols obj/primitives obj/cryptoInfra obj/circuits
INC            = -Iinstall/include -Iinstall/include/OTExtensionBristol -Iinstall/include/libOTe -Iinstall/include/libOTe/cryptoTools -Iinstall/include/gmp-6.1.2/include/
GCC_STANDARD = c++14
CPP_OPTIONS   := -std=$(GCC_STANDARD) $(INC) -Wall -Wno-narrowing -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-function -Wno-unused-variable -Wno-unused-result -Wno-sign-compare -Wno-parentheses -march=native -O3 
$(COMPILE.cpp) = g++ -c $(CPP_OPTIONS) -o $@ $<
LIBRARIES_DIR  = -Linstall/lib
LD_FLAGS = 
SUMO = no


all: libs libscapi
libs: compile-openssl compile-ntl compile-gmp compile-boost
libscapi: directories $(SLib)
directories: $(OUT_DIR)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(SLib): $(OBJ_FILES)
	ar ru $@ $^ 
	ranlib $@


obj/circuits/%.o: src/circuits/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $<
obj/comm/%.o: src/comm/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $< 	 
obj/infra/%.o: src/infra/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $< 	 
obj/interactive_mid_protocols/%.o: src/interactive_mid_protocols/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $< 	 
obj/primitives/%.o: src/primitives/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $< 	 
obj/mid_layer/%.o: src/mid_layer/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $<
obj/cryptoInfra/%.o: src/cryptoInfra/%.cpp
	$(CXX) -c $(CPP_OPTIONS) -o $@ $<

	
prepare-emp:
ifeq ($(SUMO),yes)
	@mkdir -p $(builddir)/EMP
	@cp -r lib/EMP/. $(builddir)/EMP
	@cmake -DALIGN=16 -DARCH=X64 -DARITH=curve2251-sse -DCHECK=off -DFB_POLYN=251 -DFB_METHD="INTEG;INTEG;QUICK;QUICK;QUICK;QUICK;LOWER;SLIDE;QUICK" -DFB_PRECO=on -DFB_SQRTF=off -DEB_METHD="PROJC;LODAH;COMBD;INTER" -DEC_METHD="CHAR2" -DCOMP="-O3 -funroll-loops -fomit-frame-pointer -march=native -msse4.2 -mpclmul -Wno-unused-function -Wno-unused-variable -Wno-return-type -Wno-discarded-qualifiers" -DTIMER=CYCLE -DWITH="MD;DV;BN;FB;EB;EC" -DWORD=64 $(builddir)/EMP/relic/CMakeLists.txt
	@cd $(builddir)/EMP/relic && $(MAKE)
	@cd $(builddir)/EMP/relic && $(MAKE) install
	@touch prepare-emp
endif

compile-emp-tool:prepare-emp
ifeq ($(SUMO),yes)
	@cd $(builddir)/EMP/emp-tool
	@cmake -D CMAKE_CXX_FLAGS="-Wno-unused-function -Wno-unused-variable -Wno-return-type" $(builddir)/EMP/emp-tool/CMakeLists.txt 
	@cd $(builddir)/EMP/emp-tool/ && $(MAKE)
	@cd $(builddir)/EMP/emp-tool/ && $(MAKE) install
	@touch compile-emp-tool
endif

compile-emp-ot:prepare-emp
ifeq ($(SUMO),yes)
	@cd $(builddir)/EMP/emp-ot
	@cmake -D CMAKE_CXX_FLAGS="-Wno-unused-function -Wno-unused-variable -Wno-return-type" $(builddir)/EMP/emp-ot/CMakeLists.txt 
	@cd $(builddir)/EMP/emp-ot/ && $(MAKE)
	@cd $(builddir)/EMP/emp-ot/ && $(MAKE) install
	@touch compile-emp-ot
endif
	
compile-emp-m2pc:compile-emp-ot compile-emp-tool
ifeq ($(SUMO),yes)
	@cd $(builddir)/EMP/emp-m2pc
	@cmake -D CMAKE_CXX_FLAGS="-Wno-unused-function -Wno-unused-variable -Wno-return-type -Wno-unused-result" $(builddir)/EMP/emp-m2pc/CMakeLists.txt 
	@cd $(builddir)/EMP/emp-m2pc/ && $(MAKE)
	@touch compile-emp-m2pc
endif

compile-gmp:
	@echo "Compiling the GMP library"
	@mkdir -p $(builddir)/gmp-6.1.2/
	@cp -r lib/gmp-6.1.2/. $(builddir)/gmp-6.1.2
	@cd $(builddir)/gmp-6.1.2/ && ./configure --prefix=$(prefix)/ --disable-option-checking
	@cd $(builddir)/gmp-6.1.2/ && make
	@cd $(builddir)/gmp-6.1.2/ && make install
	@mkdir -p $(prefix)/include/gmp-6.1.2/include
	@mkdir -p $(prefix)/include/gmp-6.1.2/lib
	@cp $(prefix)/include/gmp.h $(prefix)/include/gmp-6.1.2/include
	@cp install/lib/libgmp.* install/include/gmp-6.1.2/lib
	@rm $(prefix)/include/gmp.h
	@rm $(prefix)/lib/libgmp.*so*
	@rm $(prefix)/lib/libgmp.la
	@touch compile-gmp

compile-blake:
	@echo "Compiling the BLAKE2 library"
	@mkdir -p $(builddir)/BLAKE2/
	@cp -r lib/BLAKE2/sse/. $(builddir)/BLAKE2
	@$(MAKE) -C $(builddir)/BLAKE2
	@$(MAKE) -C $(builddir)/BLAKE2 --prefix=$(builddir) install
	@touch compile-blake

compile-openssl:
	@mkdir -p $(CURDIR)/install/lib
	@mkdir -p $(CURDIR)/install/include
	@mkdir -p $(builddir)/
	echo "Compiling the openssl library"
	@cp -r lib/openssl/ $(builddir)/openssl
	export CFLAGS="-fPIC"	
	cd $(builddir)/openssl/; ./config --prefix=$(builddir)/openssl/tmptrgt -no-shared 
	cd $(builddir)/openssl/; make 
	cd $(builddir)/openssl/; make install
	@cp $(builddir)/openssl/tmptrgt/lib/*.a $(CURDIR)/install/lib/
	@cp -r $(builddir)/openssl/tmptrgt/include/openssl/ $(CURDIR)/install/include/
	@touch compile-openssl

# If you want to change the build toolset : \
run bootstrap.sh \
change in project-config to the requested toolset \
then run make compile-boost

compile-boost:
	@mkdir -p $(CURDIR)/install/lib
	@mkdir -p $(CURDIR)/install/include
	@mkdir -p $(builddir)/
	echo "Compiling the boost library"
	@cp -r lib/boost_1_64_0/ $(builddir)/boost_1_64_0
	@cd $(builddir)/boost_1_64_0/; bash -c "./bootstrap.sh --prefix=. && ./b2 --with-system --with-thread";
	@cp $(builddir)/boost_1_64_0/stage/lib/*.a $(CURDIR)/install/lib/
	@cp -r $(builddir)/boost_1_64_0/boost/ $(CURDIR)/install/include/
	@touch compile-boost

compile-json:
	@echo "Compiling JSON library..."
	@cp -r lib/JsonCpp $(builddir)/JsonCpp
	@cmake $(builddir)/JsonCpp/CMakeLists.txt
	@$(MAKE) -C $(builddir)/JsonCpp/
	@cp $(builddir)/JsonCpp/src/lib_json/libjsoncpp.a $(CURDIR)/install/lib/
	@touch compile-json

# Support only in c++14
compile-libote:
	@echo "Compiling libOTe library..."
	@cp -r lib/libOTe $(builddir)/libOTe
	@mkdir -p $(builddir)/libOTe/cryptoTools/thirdparty/linux/miracl/
	@mv $(builddir)/libOTe/cryptoTools/thirdparty/linux/miracl2/* $(builddir)/libOTe/cryptoTools/thirdparty/linux/miracl/
	@cmake $(builddir)/libOTe/CMakeLists.txt -DCMAKE_BUILD_TYPE=Release
	@cd $(builddir)/libOTe/cryptoTools/thirdparty/linux/miracl/miracl/source/ && bash linux64
	@cmake $(builddir)/libOTe/CMakeLists.txt
	@$(MAKE) -C $(builddir)/libOTe/
	@cp $(builddir)/libOTe/lib/*.a $(CURDIR)/install/lib/
	@cp $(builddir)/libOTe/cryptoTools/thirdparty/linux/miracl/miracl/source/libmiracl.a $(CURDIR)/install/lib/
	@mv $(CURDIR)/install/lib/liblibOTe.a $(CURDIR)/install/lib/libOTe.a
	@mkdir -p $(CURDIR)/install/include/libOTe
	@cd $(builddir)/libOTe/ && find . -name "*.h" -type f |xargs -I {} cp --parents {} $(CURDIR)/install/include/libOTe
	@cp -r $(builddir)/libOTe/cryptoTools/cryptoTools/gsl $(CURDIR)/install/include/libOTe/cryptoTools/cryptoTools
	@touch compile-libote

compile-ntl:compile-gmp
	echo "Compiling the NTL library..."
	mkdir -p $(builddir)/NTL
	cp -r lib/NTL/unix/. $(builddir)/NTL
	chmod 777 $(builddir)/NTL/src/configure
	cd $(builddir)/NTL/src/ && ./configure CXX=$(CXX) WIZARD=off GMP_PREFIX=$(prefix)/include/gmp-6.1.2
	$(MAKE) -C $(builddir)/NTL/src/
	$(MAKE) -C $(builddir)/NTL/src/ PREFIX=$(prefix) install
	touch compile-ntl

compile-otextension-bristol: 
	@echo "Compiling the OtExtension malicious Bristol library..."
	@cp -r lib/OTExtensionBristol $(builddir)/OTExtensionBristol
	@$(MAKE) -C $(builddir)/OTExtensionBristol CXX=$(CXX)
	@$(MAKE) -C $(builddir)/OTExtensionBristol CXX=$(CXX) install
	@touch compile-otextension-bristol

clean-otextension-bristol:
	@echo "Cleaning the otextension malicious bristol build dir..."
	@rm -rf $(builddir)/OTExtensionBristol
	@rm -f compile-otextension-bristol

clean-ntl:
	echo "Cleaning the ntl build dir..."
	rm -rf $(builddir)/NTL
	rm -f compile-ntl

clean-blake:
	@echo "Cleaning blake library"
	@rm -rf $(builddir)/BLAKE2
	@rm -f compile-blake

clean-emp:
	@echo "Cleaning EMP library"
	@rm -rf $(builddir)/EMP
	@rm -f prepare-emp compile-emp-tool compile-emp-ot compile-emp-m2pc

clean-cpp:
	@echo "cleaning .obj files"
	@rm -rf $(OUT_DIR)
	@echo "cleaning lib"
	@rm -f $(SLib)

clean-install:
	@rm -rf install/*

clean-tests:
	@rm -f test/tests.exe

clean-boost:
	@echo "Cleaning boost library"
	@rm -rf $(builddir)/boost_1_64_0
	@rm -f compile-boost
	
clean-openssl:
	@echo "Cleaning openssl library"
	@rm -rf $(builddir)/openssl
	@rm -f compile-openssl

clean-gmp:
	@rm -rf $(builddir)/gmp-6.1.2/
	@rm -f $(CURDIR)/install/lib/gmp*
	@rm -rf compile-gmp

clean-json:
	@echo "Cleaning JSON library"
	@rm -rf $(builddir)/JsonCpp/
	@rm -f compile-json

clean-libote:
	@echo "Cleaning libOTe library"
	@rm -rf $(builddir)/libOTe/
	@rm -f compile-libote

clean: clean-json clean-libote clean-openssl clean-gmp clean-boost clean-emp clean-otextension-bristol clean-ntl clean-install clean-tests

