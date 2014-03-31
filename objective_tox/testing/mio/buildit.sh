cc -I../../core/toxcore -I../../core_extensions -I../../../txd_plus \
   -I../../../txd_plus/scrypt-jane -I/usr/local/include \
   -DSCRYPT_CHACHA -DSCRYPT_KECCAK512 \
   -no-integrated-as -march=native -L/usr/local/lib -lsodium \
   ../../core/toxcore/*.c ../../core_extensions/*.c ../../../txd_plus/*.c \
   ../../../txd_plus/scrypt-jane/scrypt-jane.c mio.c \
   -o mio