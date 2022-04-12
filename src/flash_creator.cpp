// cart_creator.cpp
// EP (C) 2021-04-30

// This simple program creates a flash image for a single cartridge or file.

#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#include <list>
#include <string>
#include <algorithm>  // min

#include <flash_header.h>

using namespace std;
string cart_name;
string rom_name;
string out_name;
string grom_name;
string file_name;
string sysgrom_name;
string arm_name;
bool minimem = false;
bool gshrink = false;
bool append = false;
bool enable_ram = false;  // Make ROM writable

list<unsigned char *> free_list;

void free_all() {
  list<unsigned char *>::iterator it;
  for(it = free_list.begin(); it != free_list.end(); ++it) {
    delete[] *it;
  }
}

unsigned char *get_file(string name, int &len) {
  struct stat st;
  FILE *f = fopen(name.c_str(), "rb");
  if(f == NULL) {
    if(name.length() > 0)
      fprintf(stderr, "Unable to open %s\n", name.c_str());
    return NULL;
  }
  if(fstat(fileno(f), &st)) {
    fprintf(stderr, "Unable to stat %s\n", name.c_str());
    return NULL;
  }
  int size = st.st_size;
  len = size;
  unsigned char *p = new unsigned char [size];
  free_list.push_back(p);
  int rd = 0;
  unsigned char *d = p;
  do {
    int r = fread(d, sizeof(unsigned char), st.st_size - (d-p), f);
    d += r;
  } while((d-p) < st.st_size);
  fclose(f);
  printf("(%s read %ld bytes) ", name.c_str(), d-p);
  return p;
}

class deletor {
  public:
    virtual ~deletor() {
      free_all();
    }
};

int main(int argc, char *argv[]) {
  deletor dt;

  if(argc < 3) {
    fprintf(stderr, "flash_creator: create a simple flash binary image\n"
      "\t-name <name>     Output cartridge or file name\n"
      "\t-out <filename>  Give a name to the output file\n"
      "\t-grom <filename> Input GROM filename\n"
      "\t-rom <filename>  Input ROM image\n"
      "\t-file <filename> Make a file, not a ROM image, from contents of the file.\n"
      "\t-minimem         Make a minimem style cartridge, 4K ROM 4K RAM\n"
      "\t-sysgrom <filename> Override system GROM\n"
      "\t-arm <filename>  Input ARM binary\n"
      "\t-gshrink         Shrink last GROM to 6K.\n"
      "\t-append          Append to output file.\n"
      "\tExample:\n"
      "\t./flash_creator -name \"TI Invaders\" -out invaders.bin -rom roms/TI-InvaC.Bin -grom roms/TI-InvaG.Bin -gshrink\n"
      );
      return 0;
  }
  for(int i=1; i<argc; i++) {
    if(!strcmp(argv[i], "-name"))       { cart_name = argv[i+1]; i++; } 
    else if(!strcmp(argv[i], "-out"))   { out_name  = argv[i+1]; i++; } 
    else if(!strcmp(argv[i], "-grom"))  { grom_name = argv[i+1]; i++; }
    else if(!strcmp(argv[i], "-rom"))   { rom_name = argv[i+1]; i++; }
    else if(!strcmp(argv[i], "-file"))  { file_name = argv[i+1]; i++; }
    else if(!strcmp(argv[i], "-minimem")) { minimem = true; }
    else if(!strcmp(argv[i], "-sysgrom")) { sysgrom_name = argv[i+1]; i++; } 
    else if(!strcmp(argv[i], "-arm"))   { arm_name = argv[i+1]; i++; }
    else if(!strcmp(argv[i], "-gshrink"))  { gshrink = true; }
    else if(!strcmp(argv[i], "-append")){ append = true; }
    else if(!strcmp(argv[i], "-ram"))   { enable_ram = true; }
    else {
      fprintf(stderr, "Error, unknown parameter: %s", argv[i]);
      return 5;
    }
  }

  // Ok make sanity checks.
  bool is_cart = rom_name.length() || grom_name.length() || sysgrom_name.length() || arm_name.length();
  bool is_file = !!file_name.length();
  if(is_cart && is_file) {
    fprintf(stderr, "A flash image can either be for a file, or a cartridge, not both.\n"
      "The -file parameter cannot be combined with cart memory types.\n"
      );
    return 6;
  }
  if(!is_file && !is_cart) {
    fprintf(stderr, "Image needs to be either file or cartridge.\n"
      "Specify -file or one of the ROM parameters.\n");
      return 6;
  }
  if(cart_name.length() == 0 || cart_name.length() > 32) {
    fprintf(stderr, "Cartridge/file name must be specified and maximum length is 32 characters.\n");
    return 7;
  }

  if(out_name.length() == 0) {
    fprintf(stderr, "No output filename given. -out is necessary.\n");
    return 8;
  }

  rom_flash_header h;
  memset(&h, 0, sizeof(h));
  h.size = sizeof(h);
  memcpy(h.id, "SC21", sizeof(h.id));
  int l = cart_name.length();
  memcpy(h.name, cart_name.c_str(), min(l, (int)sizeof(h.name)));
  h.flags |= minimem ? FLAG_MINIMEMORY : 0;
  h.flags |= is_file ? FLAG_FILE : FLAG_CARTRIDGE;
  h.flags |= h.u.cart.sysgrom_size > 0 ? FLAG_SYSGROM : 0;
  h.flags |= enable_ram ? FLAG_RAM : 0;

  unsigned char *p[4];
  int s[4];
  memset(p, 0, sizeof(p));
  memset(s, 0, sizeof(s));

  if(is_file) {
    printf("Generating file (%s): ", cart_name.c_str());
    p[0] = get_file(file_name, h.u.file.file_size);
    s[0] = h.u.file.file_size;
    h.u.file.file_alloc_size = h.u.file.file_size;
    printf("File alloc size %d and file size %d\n", h.u.file.file_alloc_size, h.u.file.file_size);
  } else {
    printf("Generating cartridge (%s): ", cart_name.c_str());
    p[0] = get_file(grom_name,    h.u.cart.grom_size);
    p[1] = get_file(rom_name,     h.u.cart.rom_size);
    p[2] = get_file(sysgrom_name, h.u.cart.sysgrom_size);
    p[3] = get_file(arm_name,     h.u.cart.arm_size);

    s[0] = h.u.cart.grom_size;
    s[1] = h.u.cart.rom_size;
    s[2] = h.u.cart.sysgrom_size;
    s[3] = h.u.cart.arm_size;

    if(gshrink && s[0]) {
      // Resize (potentially) GROM to 6K.
      // See if GROM is multiple of 6K and 8K.
      int gs6 = s[0] % 6144;  // remainders
      int gs8 = s[0] % 8192;
      if(!gs8 && gs6) {
        // Multiple of 8K but not multiple of 6K - shrink.
        // This is useful to fit the header into the same 4K page.
        int os = s[0];
        s[0] = h.u.cart.grom_size = os - 2048;
        printf("Shrinking GROM from %d to %d bytes.", os, s[0]);
      }
    }
  }
  printf("\n");

  // Ok time to spit out the whole thing.
  FILE *dest = fopen(out_name.c_str(), append ? "ab" : "wb");
  if(dest == NULL) {
    fprintf(stderr, "Unable to open destination file: %s\n", out_name.c_str());
    return 9;
  }
  int written = 0;
  if(fwrite(&h, sizeof(h), 1, dest))
    written += sizeof(h);
  for(int i=0; i<4; i++) {
    if(p[i]) {
      int k = fwrite(p[i], sizeof(unsigned char), s[i], dest);
      written += k;
      if(k != s[i]) {
        fprintf(stderr, "Failed to write entire file %d\n", i);
        return 10;
      }
    } 
  }

  // Aling to 4K by padding 0xFF to the end.
  while(written & 0xFFF) {
    unsigned char ff = 0xFF;
    written += fwrite(&ff, sizeof(ff), 1, dest);
  }
  fclose(dest);
  printf("Destination size %d\n\n", written);
  
  return 0;
}
