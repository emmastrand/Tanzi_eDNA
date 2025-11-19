# Reading a MultiQC Report

General Statistics:  
- Percent duplicates: High duplication is expected for PCR-based amplicon sequencing and does not indicate low complexity as it would in shotgun data. Extremely high duplication often reflects low eDNA template concentrations where a few molecules dominate amplification.  
- Percent GC: Amplicons usually have a predictable GC% based on the target locus. Deviations or broad distributions suggest off-target amplification, mixed-taxon templates, or contamination in low-biomass eDNA samples.    
- Number of reads (millions of sequences): Read counts vary widely in eDNA samples depending on biomass and inhibitor load. Low read numbers often reflect poor amplification success due to degradation or environmental inhibitors.   

Sequence Counts

**Sequence Quality Histogram**: Shows the distribution of quality scores at each base position across all reads and highlights systematic end-of-read drops. For amplicons from eDNA, slight quality reduction at ends is common and usually reflects degraded template or primer heterogeneity.  

**Per sequence quality scores**: Summarizes overall read-level quality to detect globally low-quality libraries. eDNA samples sometimes show lower-quality subsets due to inhibitors or highly degraded DNA.

**Per base sequence content**: Reports the proportion of A/C/G/T at each position; primer sites produce strong, expected base biases. Beyond primer regions, irregularities often reflect genuine taxonomic diversity in mixed-template eDNA samples.

**Per sequence GC content**: Compares observed GC% to an expected model; single-locus amplicons should show a tight peak. Broadened or multimodal peaks in eDNA datasets typically indicate off-target PCR products, mixed-taxon amplification, or low-template artifacts.

**Per base N content**: Measures frequency of ambiguous bases. Slight elevations are common in eDNA due to degraded DNA, while sharp increases signal poor sequencing or substantial template decay.

**Sequence length distribution**: Shows read-length distribution; well-behaved amplicon libraries have a narrow band at the expected length. Extra peaks suggest non-specific PCR products, primer dimers, or degraded eDNA fragments.

**Sequence duplication levels**: Quantifies duplicated reads. High duplication is an inherent feature of amplicon PCR, and extremely high duplication often indicates very low starting template in eDNA samples.

**Overrepresented sequences by sample**: Lists sequences occurring more frequently than expected. In eDNA amplicons, these may represent primer dimers, dominant taxa, or non-specific products that preferentially amplified from low-template mixtures.

**Top overrepresented sequences**: Provides the most frequent overrepresented sequences across samples. These often correspond to primer sequences, synthetic constructs, or highly abundant taxa; in eDNA, they can reveal contamination or unexpected non-target amplification.

**Adapter content**: Estimates remaining adapter sequence in reads. High adapter content in eDNA amplicons typically reflects short degraded fragments or excessive primer-dimer formation rather than issues with library prep.