/* See https://github.com/sschaetz/nvidia-opencl-examples/blob/master/OpenCL/src/oclMatVecMul/oclMatVecMul.cl */

__kernel
void single_scan0(
		__constant const uchar *bitcount_table,
		__global const ulong *bitstrings,
		const uint bs_len,
		const uint sample,
		__constant const ulong *bs,
		const uint radius,
		__global uint *counter,
		__global uint *selected,
		__local uint *partial_dist)
{
	uint id = get_global_id(0);

	if (id < sample) {
		ulong a;
		uint dist;

		const __global ulong *row = bitstrings + id*bs_len;

		dist = 0;
		for(uint j=0; j<bs_len; j++) {
			a = row[j] ^ bs[j];
			dist += popcount(a);
		}
		if (dist <= radius) {
			selected[atomic_inc(counter)] = id;
		}
	}
}

__kernel
void single_scan1(
		__constant const uchar *bitcount_table,
		__global const ulong *bitstrings,
		const uint bs_len,
		const uint sample,
		__constant const ulong *bs,
		const uint radius,
		__global uint *counter,
		__global uint *selected,
		__local uint *partial_dist)
{
	uint id;
	ulong a;
	uint dist;
	const __global ulong *row;
	
	for (id=get_global_id(0); id < sample; id += get_global_size(0)) {

		row = bitstrings + id*bs_len;

		dist = 0;
		for(uint j=0; j<bs_len; j++) {
			a = row[j] ^ bs[j];
			dist += popcount(a);
		}
		if (dist <= radius) {
			selected[atomic_inc(counter)] = id;
		}

	}
}

__kernel
void single_scan2(
		__constant const uchar *bitcount_table,
		__global const ulong *bitstrings,
		const uint bs_len,
		const uint sample,
		__constant const ulong *bs,
		const uint radius,
		__global uint *counter,
		__global uint *selected,
		__local uint *partial_dist)
{
	uint dist;
	ulong a;
	uint j;

	for (uint id = get_group_id(0); id < sample; id += get_num_groups(0)) {

		const __global ulong *row = bitstrings + id*bs_len;

		dist = 0;
		j = get_local_id(0);
		if (j < bs_len) {
			a = row[j] ^ bs[j];
			dist += popcount(a);
		}
		partial_dist[get_local_id(0)] = dist;

		barrier(CLK_LOCAL_MEM_FENCE);

		if (get_local_id(0) == 0) {
			dist = 0;
			for(uint t = 0; t < bs_len; t++) {
				dist += partial_dist[t];
			}
			if (dist <= radius) {
				selected[atomic_inc(counter)] = id;
			}
		}

		barrier(CLK_LOCAL_MEM_FENCE);
	}
}

__kernel
void single_scan(
		__constant const uchar *bitcount_table,
		__global const ulong *bitstrings,
		const uint bs_len,
		const uint sample,
		__constant const ulong *bs,
		const uint radius,
		__global uint *counter,
		__global uint *selected,
		__local uint *partial_dist)
{
	uint dist;
	ulong a;
	uint j;

	for (uint id = get_group_id(0); id < sample; id += get_num_groups(0)) {

		const __global ulong *row = bitstrings + id*bs_len;

		dist = 0;
		j = get_local_id(0);
		if (j < bs_len) {
			a = row[j] ^ bs[j];
			dist += popcount(a);
		}
		partial_dist[get_local_id(0)] = dist;

		// Parallel reduction to sum all partial_dist array.
		for(uint stride = get_local_size(0) / 2; stride > 0; stride /= 2) {
			barrier(CLK_LOCAL_MEM_FENCE);

			if (get_local_id(0) < stride) {
				partial_dist[get_local_id(0)] += partial_dist[get_local_id(0) + stride];
			}
		}

		if (get_local_id(0) == 0) {
			if (partial_dist[0] <= radius) {
				selected[atomic_inc(counter)] = id;
			}
		}

		barrier(CLK_LOCAL_MEM_FENCE);
	}
}
