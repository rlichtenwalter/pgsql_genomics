CC := gcc
CFLAGS := -std=gnu89 -Wall -Wextra -Werror -O3

all: array_multi_index.so summarize_variant.so imputed_genotype.so 

%.o: %.c
	$(CC) $(CFLAGS) -I/usr/pgsql-9.4/include/server -fpic -c $<

%.so: %.o
	$(CC) $(CFLAGS) -shared -o $@ $<

.PHONY: clean

clean:
	rm -f *.o *.so

