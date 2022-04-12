// flash_header.h
// EP (C) 2021-04-30
 
#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#define FLAG_MINIMEMORY (1)
#define FLAG_SYSGROM    (2)
#define FLAG_ROMBANKED  (4)
#define FLAG_CARTRIDGE  (8) 
#define FLAG_FILE       (16)  // Not a cart, but a file
#define FLAG_RAM        (32)  // Map RAM to >6000

// ROM flash header structures are written to FLASH preceeding actual data.
// They are written in 4K aligned locations to support flash sector erase.

struct cart_t {
  int   grom_size;  // Size (in bytes) of GROM content following after the header. 0 if none.
  int   rom_size;   // Size (in bytes) of ROM content following GROM content.
  int   sysgrom_size; // Size (in bytes) of system GROM replacement, after ROM.
  int   arm_size;   // Size (in bytes) of ARM code associated with the cartridge. Loaded and executed in RAM.
};

struct file_t {
  int   file_size;  // If this is a file, current size of the file.
  int   file_alloc_size;  // If this is a file, the allocated size of the file.
};

struct rom_flash_header {
  char  id[4];      // "SC21" - strangecart 2 header id
  int   size;       // Size of this header structure.
  char  name[32];   // Name of the cartridge or name of the file if this is a file.
  int   flags;
  union u_t {
    struct cart_t cart;
    struct file_t file;
  } u;
  char pad[4];      // Pad to 64 bytes. Makes for nicer hexdumps.
};

#ifdef __cplusplus
}
#endif
