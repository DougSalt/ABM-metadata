. $PWD/bin/path.sh

export REQUIRED_NOF_CPUS=4
export PATH=$PWD/example:$PATH

#export test=1
#export SSREPI_DEBUG=True

export SSREPI_DBTYPE=postgres
# Stupid, stupid, stupid - DO NOT DO THE FOLLOWING
# export SSREPI_DBFILE=$(pwd)/ssrep.db
export SSREPI_DBFILE=~/ssrep.db
export SSREPI_MAX_PROCESSES=256
#export SSREPI_DBUSER=doug
export SSREPI_DBUSER=ds42723
export SSREPI_SLURM=1
#export SSREPI_SLURM_PENDING_BLOCKS=True

