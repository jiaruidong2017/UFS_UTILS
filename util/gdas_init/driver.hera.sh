#!/bin/bash

#---------------------------------------------------------------------
# Driver script for running on Hera.
#
# Edit the 'config' file before running.
#---------------------------------------------------------------------

set -x

source ../../sorc/machine-setup.sh > /dev/null 2>&1
source ../../modulefiles/build.$target

PROJECT_CODE=fv3-cpu
QUEUE=batch

source config

if [ $EXTRACT_DATA == yes ]; then

  rm -fr $EXTRACT_DIR
  mkdir -p $EXTRACT_DIR

  MEM=6000M
  WALLT="2:00:00"

  case $gfs_ver in
    v12 | v13)
      DATAH=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_hires \
       -o log.data.hires -e log.data.hires ./get_pre-v14.data.sh hires)
      DATA1=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_enkf \
       -o log.data.enkf -e log.data.enkf ./get_pre-v14.data.sh enkf)
      DEPEND="-d afterok:$DATAH:$DATA1"
      ;;
    v14)
      DATAH=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_hires \
       -o log.data.hires -e log.data.hires ./get_v14.data.sh hires)
      DATA1=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_enkf \
       -o log.data.enkf -e log.data.enkf ./get_v14.data.sh enkf)
      DEPEND="-d afterok:$DATAH:$DATA1"
      ;;
    v15)
      DATAH=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_hires \
       -o log.data.hires -e log.data.hires ./get_v15.data.sh hires)
      DATA1=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp1 \
       -o log.data.grp1 -e log.data.grp1 ./get_v15.data.sh grp1)
      DATA2=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp2 \
       -o log.data.grp2 -e log.data.grp2 ./get_v15.data.sh grp2)
      DATA3=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp3 \
       -o log.data.grp3 -e log.data.grp3 ./get_v15.data.sh grp3)
      DATA4=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp4 \
       -o log.data.grp4 -e log.data.grp4 ./get_v15.data.sh grp4)
      DATA5=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp5 \
       -o log.data.grp5 -e log.data.grp5 ./get_v15.data.sh grp5)
      DATA6=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp6 \
       -o log.data.grp6 -e log.data.grp6 ./get_v15.data.sh grp6)
      DATA7=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp7 \
       -o log.data.grp7 -e log.data.grp7 ./get_v15.data.sh grp7)
      DATA8=$(sbatch --parsable --partition=service --ntasks=1 --mem=$MEM -t $WALLT -A $PROJECT_CODE -q $QUEUE -J get_grp8 \
       -o log.data.grp8 -e log.data.grp8 ./get_v15.data.sh grp8)
      DEPEND="-d afterok:$DATAH:$DATA1:$DATA2:$DATA3:$DATA4:$DATA5:$DATA6:$DATA7:$DATA8"
      ;;
 esac

else

  DEPEND=' '

fi

if [ $RUN_CHGRES == yes ]; then
  export APRUN=srun
  MEMBER=hires
  NODES=3
  WALLT="0:15:00"
  export OMP_NUM_THREADS=1
  if [ $CRES_HIRES == 'C768' ] ; then
    NODES=5
  elif [ $CRES_HIRES == 'C1152' ] ; then
    NODES=8
    WALLT="0:20:00"
  fi
  case $gfs_ver in
    v12 | v13)
      export OMP_NUM_THREADS=4
      export OMP_STACKSIZE=1024M
      sbatch --parsable --ntasks-per-node=6 --nodes=${NODES} --cpus-per-task=$OMP_NUM_THREADS \
        -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER} \
        -o log.${MEMBER} -e log.${MEMBER} ${DEPEND} run_pre-v14.chgres.sh ${MEMBER}
      ;;
    v14)
      sbatch --parsable --ntasks-per-node=6 --nodes=${NODES} -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER} \
      -o log.${MEMBER} -e log.${MEMBER} ${DEPEND} run_v14.chgres.sh ${MEMBER}
      ;;
    v15)
      sbatch --parsable --ntasks-per-node=6 --nodes=${NODES} -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER} \
      -o log.${MEMBER} -e log.${MEMBER} ${DEPEND} run_v15.chgres.sh ${MEMBER}
      ;;
  esac

  WALLT="0:15:00"
  MEMBER=1
  while [ $MEMBER -le 80 ]; do
    if [ $MEMBER -lt 10 ]; then
      MEMBER_CH="00${MEMBER}"
    else
      MEMBER_CH="0${MEMBER}"
    fi
    case $gfs_ver in
      v12 | v13)
        export OMP_NUM_THREADS=2
        export OMP_STACKSIZE=1024M
        sbatch --parsable --ntasks-per-node=12 --nodes=1 --cpus-per-task=$OMP_NUM_THREADS \
         -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER_CH} \
         -o log.${MEMBER_CH} -e log.${MEMBER_CH} ${DEPEND} run_pre-v14.chgres.sh ${MEMBER_CH}
        ;;
      v14)
        sbatch --parsable --ntasks-per-node=12 --nodes=1 -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER_CH} \
        -o log.${MEMBER_CH} -e log.${MEMBER_CH} ${DEPEND} run_v14.chgres.sh ${MEMBER_CH}
        ;;
      v15)
        sbatch --parsable --ntasks-per-node=12 --nodes=1 -t $WALLT -A $PROJECT_CODE -q $QUEUE -J chgres_${MEMBER_CH} \
        -o log.${MEMBER_CH} -e log.${MEMBER_CH} ${DEPEND} run_v15.chgres.sh ${MEMBER_CH}
      ;;
    esac
    MEMBER=$(( $MEMBER + 1 ))
  done

fi
