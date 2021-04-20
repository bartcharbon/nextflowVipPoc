# Nextflow and Singularity PoC for the VIP project

This proof of concept will take an non compressed input vcf and:
- compress it
- index it
- split it per chromsome in to separate vcf file
- run the vip-decision-tree on the per-chromsome vcf's (Parallel)
- merge the result back together
- run the vip-report on the merged vcf

# Prerequisite
This PoC assumes [Singularity](https://sylabs.io/guides/3.5/admin-guide/installation.html) and [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) are installed.

# Installation
Checkout the git repository:
```
git clone https://github.com/bartcharbon/nextflowVipPoc.git
cd nextflowVipPoc/
```
NOTE: in a production setup the singularity images would be retrieved from a registry.
For this PoC you have 2 options:

1) Use the definitions provided in this repository to build the necessary images;
```
sudo singularity build ./workdir/tabix.sif ./singularity/tabix.def
sudo singularity build ./workdir/vip-decision-tree.sif ./singularity/vip-decision-tree.def
sudo singularity build ./workdir/vip-report.sif ./singularity/vip-report.def
```

2) Download the images from [here](https://drive.google.com/file/d/1vCIp9K5pq4gPDRS_j6LOAceArXrx_tcy/view?usp=sharing).
The tar.gz file should be extracted in the "/workdir/" folder of this project.

# Running the pipeline
If you have slurm installed:
```
nextflow ./nextflow/vip.nf -c ./nextflow/vip.config --input ./data/patient_mother_father.vcf
```
If you do not have slurm installed:
```
nextflow ./nextflow/vip.nf -c ./nextflow/vip_noslurm.config --input ./data/patient_mother_father.vcf
```
The nextflow output will point you to the generated report html file.
