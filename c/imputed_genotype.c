#include <postgres.h>
#include <fmgr.h>
#include <stdint.h>
#include <stdio.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1( imputed_genotype_in );
Datum imputed_genotype_in( PG_FUNCTION_ARGS ) {
	char *str = PG_GETARG_CSTRING( 0 );
	float fprob1;
	float fprob2;
	float fprob3;
	if( sscanf( str, "{%f,%f,%f}", &fprob1, &fprob2, &fprob3 ) != 3 ) {
		ereport( ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),errmsg("invalid input syntax for imputed_genotype: \"%s\"", str)) );
	}
	if( fprob1 < 0.0 || fprob2 < 0.0 || fprob3 < 0.0 ) {
		ereport( ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),errmsg("imputed_genotype probabilities must all be positive: \"%s\"", str)) );
	}
	unsigned int iprob1 = (unsigned int)(fprob1*1000);
	unsigned int iprob2 = (unsigned int)(fprob2*1000);
	unsigned int iprob3 = (unsigned int)(fprob3*1000);
	if( iprob1 + iprob2 + iprob3 > 1001 ) { // 1001 vs. 1000 to allow for rounding issues
		ereport( ERROR, (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),errmsg("imputed_genotype probabilities must sum to <= 1.0: \"%s\"", str)) );
	}
	unsigned int imputed_genotype = (iprob1 << 20) | (iprob2 << 10) | iprob3;
	PG_RETURN_INT32( imputed_genotype );
}

PG_FUNCTION_INFO_V1( imputed_genotype_out );
Datum imputed_genotype_out( PG_FUNCTION_ARGS ) {
	unsigned int imputed_genotype = PG_GETARG_INT32( 0 );
	unsigned int iprobs[3];
	iprobs[0] = imputed_genotype >> 20;
	iprobs[1] = (imputed_genotype << 12) >> 22;
	iprobs[2] = (imputed_genotype << 22) >> 22;
	char* result = (char*)palloc( 20*sizeof(char) );
	int offset = 0;
	result[ offset++ ] = '{';
	unsigned int i;
	for( i = 0; i < 3; ++i ) {
		if( iprobs[i] >= 1000 ) {
			result[ offset++ ] = '1';
		} else {
			result[ offset++ ] = '0';
			if( iprobs[i] > 0 ) {
				result[ offset++ ] = '.';
				offset += snprintf( &result[offset], 4, "%03d", iprobs[i] );
			}
		}
		if( i < 2 ) {
			result[ offset++ ] = ',';
		}
	}
	result[ offset++ ] = '}';
	result[ offset++ ] = '\0';
	PG_RETURN_CSTRING( result );
}

