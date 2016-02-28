#include <postgres.h>
#include <utils/lsyscache.h>
#include <utils/array.h>
#include <funcapi.h>
#include <access/htup_details.h>
#include <stddef.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1( summarize_variant );
Datum summarize_variant( PG_FUNCTION_ARGS ) {
	if( PG_ARGISNULL(0) ) {
		ereport( ERROR, (errmsg("summarize_variant: array of values must be non-null")) );
	}

	TupleDesc tuple_desc;
	if( get_call_result_type( fcinfo, NULL, &tuple_desc ) != TYPEFUNC_COMPOSITE ) {
		ereport( ERROR, (errmsg("summarize_variant: function returning composite type called in context that cannot accept composite type")) );
	}
	tuple_desc = BlessTupleDesc( tuple_desc );

	ArrayType* values = PG_GETARG_ARRAYTYPE_P( 0 );

	Oid values_type = ARR_ELEMTYPE( values );
	int16 values_width;
	bool values_passbyvalue;
	char values_alignmentcode;
	Datum* values_content;
	bool* values_nullflags;
	int values_length;
	get_typlenbyvalalign( values_type, &values_width, &values_passbyvalue, &values_alignmentcode );
	deconstruct_array( values, values_type, values_width, values_passbyvalue, values_alignmentcode, &values_content, &values_nullflags, &values_length );

	size_t composite_type_elements = 9;
	Datum* results_content = (Datum*)palloc0( sizeof(Datum) * composite_type_elements );
	bool* results_nullflags = (bool*)palloc0( sizeof(bool) * composite_type_elements );
	// FORMAT
	// [0] - call rate
	// [1] - subset call rate
	// [2] - alternate allele frequency
	// [3] - sample alternate allele frequency


	if( !PG_ARGISNULL(1) ) {
		ArrayType* indices = PG_GETARG_ARRAYTYPE_P(1);
		Oid indices_type = ARR_ELEMTYPE( indices );
		int16 indices_width;
		bool indices_passbyvalue;
		char indices_alignmentcode;
		Datum* indices_content;
		bool* indices_nullflags;
		int indices_length;
		get_typlenbyvalalign( indices_type, &indices_width, &indices_passbyvalue, &indices_alignmentcode );
		deconstruct_array( indices, indices_type, indices_width, indices_passbyvalue, indices_alignmentcode, &indices_content, &indices_nullflags, &indices_length );
		int count = 0;
		int nonnull_count = 0;
		int alternate_count = 0;
		int i;
		for( i = 0; i < indices_length; ++i ) {
			if( !indices_nullflags[i] && indices_content[i] - 1 < (long unsigned)values_length ) {
				++count;
				if( !values_nullflags[ indices_content[i] - 1 ] ) {
					++nonnull_count;
					alternate_count += values_content[ indices_content[i] - 1 ];
				}
			}
		}
		results_content[1] = Float4GetDatum( nonnull_count / (float4)count );
		results_content[3] = Float4GetDatum( nonnull_count == 0 ? 0 : alternate_count/(2.0*nonnull_count) );
		results_nullflags[3] = nonnull_count == 0;
	} else {
		results_nullflags[1] = true;
		results_nullflags[3] = true;
	}

	int count = values_length;
	unsigned int nonnull_count = 0;
	unsigned int alternate_count = 0;
	int i;
	for( i = 0; i < values_length; ++i ) {
		if( !values_nullflags[i] ) {
			++nonnull_count;
			alternate_count += values_content[i];
		}
	}

	results_content[0] = Float4GetDatum( nonnull_count / (float4)count );
	results_content[2] = Float4GetDatum( nonnull_count == 0 ? 0 : alternate_count/(2.0*nonnull_count) );
	results_nullflags[2] = nonnull_count == 0;

	HeapTuple tuple = heap_form_tuple( tuple_desc, results_content, results_nullflags );
	Datum result = HeapTupleGetDatum( tuple );
	PG_RETURN_DATUM( result );
}

