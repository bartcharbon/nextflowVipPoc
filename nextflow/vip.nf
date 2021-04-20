nextflow.enable.dsl=2 
version="0.0.1" 

process compressVcf {
	input:
	tuple val(vcfId), path(vcf)
	output:
	tuple val(vcfId), path("${vcf.name}.gz")
	script:
	"""
	bgzip -c $vcf > ${vcf.name}.gz
	"""
}

process indexVcf {
	input:
	tuple val(vcfId), path(vcf)
	output:
	tuple val(vcfId), path(vcf), path("${vcf}.tbi")
	script:
	"""
	tabix -p vcf $vcf
	"""
}

process listVcfChroms {
	input:
	tuple val(vcfId), path(vcf), path(tbi)
	output:
	tuple val(vcfId), path(vcf), path(tbi), stdout
	script:
	"""
	tabix -l $vcf
	"""
}

process splitVcf {
	input:
	tuple val(vcfId), val(chrom), path(vcf), path(tbi)
	output:
	tuple val(vcfId), path("${vcfId}_${chrom}.vcf")
	script:
	"""
	tabix -h $vcf $chrom > ${vcfId}_${chrom}.vcf
	"""
}

process classifyVcf {
	input:
	tuple val(vcfId), path(vcf)
	output:
	tuple val(vcfId), path("${vcf.baseName}_classified.vcf")
	script:
	"""
	java -jar /vip/vcf-decision-tree.jar -i $vcf -c /vip/default.json -o ${vcf.baseName}_classified.vcf
	"""
}

process mergeVcf {
	input:
	tuple val(vcfId), val(vcfs)
	output:
	tuple val(vcfId), path("${vcfId}.vcf.gz")
	script:
	files=vcfs.join(" ")
	"""
	bcftools concat -Oz -o ${vcfId}.vcf.gz $files
	"""
}

process report {
	input:
	tuple val(vcfId), path(vcf)
	output:
	tuple val(vcfId), path("${vcf.name}.html")
	script:
	"""
	java -jar /vip/vcf-report.jar -i $vcf -o ${vcf.name}.html
	"""
}

def flatMapVcfChroms(vcfId, vcf, tbi, stdout) {
	list = []
	chroms = stdout.split("[\\r\\n]+")
	for(chrom in chroms) {
		list.add(tuple(vcfId, chrom, vcf, tbi))
	}
	return list
}

workflow runWorkflow {
	take: data
	main:
		data | \
		map { file -> tuple(file.baseName, file) } | \
		compressVcf | \
		indexVcf | \
		listVcfChroms | \
		flatMap { vcfId, vcf, tbi, stdout -> flatMapVcfChroms(vcfId, vcf, tbi, stdout) } | \
		splitVcf | \
		classifyVcf | \
		groupTuple(by: 0) | \
		mergeVcf | \
		report | \
		view
	emit:
		report.out
}

def printUsage() {
	println "usage: --input <arg>"
	println ""
	println "--input <arg> Input VCF file (.vcf)."
}

workflow {
	if(params.containsKey("version")) {
		println version
		exit 0
	}
	if(!params.containsKey("input")) {
		println "error: missing required option --input"
		println ""
		printUsage()
		exit 1
	}
	params.outdir = "$PWD/out"
	channel.fromPath(params.input) | runWorkflow | view
}
