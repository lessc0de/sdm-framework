
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "address_space.h"
#include "scanner_opencl.h"
#include "counter.h"

int main(void) {
	struct address_space_s as;
	bitstring_t *bs1;
	char buf[1000];
	int i;

	int bits = 1000;
	int sample = 1000000;

	//int status = as_init_from_b64_file(&as, "test1_address_space_b64.as");
	//assert(status == 0);

	assert(!as_init_random(&as, bits, sample));
	//as_save_b64_file(&as, "test1_address_space_b64.as");

	as_print_summary(&as);
	
	bs_init_bitcount_table();

	bs1 = bs_alloc(as.bs_len);
	bs_init_random(bs1, as.bs_len, as.bs_bits_remaining);
	bs_to_hex(buf, bs1, as.bs_len);
	printf("bs1 = %s\n", buf);

	//for(i=0; i<8*as.bs_len*sizeof(bitstring_t); i++) {
	//	printf("%d", bs_get_bit(bs1, i));
	//}
	//printf("\n");

	unsigned int selected_linear[sample];
	for (i=0; i<1000; i++) {
		as_scan_linear2(&as, bs1, 451, selected_linear);
	}
	printf("Done.\n");

	bs_free(bs1);
	return 0;
}

