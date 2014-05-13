#!/bin/bash
#
# checklibs.sh
# Objective: Verify Platform, OS Version, Kernel and Packages requirements
#
###############################################################################
# Date     # Who # Comment                                                    #
###############################################################################
# 20140513 # PNE # Initial version                                            #


#
# Objective: Test if Oracle Linux release is at minimum specified level 
# Usage: testLinuxRel {Release}U{UpdateLevel}
#        
# Returns:
# 	SUCCESS		Current Linux release is at specified level	
# 	FAIL		Current Linux release is not at specified minimum level
#
function testLinuxRel() {
       
      	if [[ $1 =~ ^[0-9]*UL[0-9]*$ ]] ; then
          minlevel=$1
       	else
          echo -e "\nUse correct format {minver}UL[minupdate]"
          echo -e "Examples; 5UL 5UL3 6UL2\n"
	  return 2
	fi
 
	rpmRelease=`rpm -qf /etc/redhat-release`
	distribution=""
	
	if [[ :${rpmRelease:0:7}: == :redhat-: ]] ; then
	  distribution="Redhat"
	elif [[ :${rpmRelease:0:11}: == :enterprise-: ||
	        :${rpmRelease:0:12}: == :oraclelinux-: ]] ; then
	  distribution="Oracle"
	fi
	
	redhatRelease=`sed 's/^[a-zA-Z[:blank:]]*\([0-9]*\)\.\([0-9]\).*/\1UL\2/' /etc/redhat-release`
	
	if [[ :$minlevel: != :: ]] ; 
	then
	  currVersion=`sed 's/^[a-zA-Z[:blank:]]*\([0-9]*\)\.\([0-9]\).*/\1/' /etc/redhat-release`
	  currUpdatelevel=`sed 's/^[a-zA-Z[:blank:]]*\([0-9]*\)\.\([0-9]\).*/\2/' /etc/redhat-release`
	
	  reqVersion=`echo $minlevel | sed 's/^\([0-9]*\)UL\([0-9]*\)$/\1/'`
	  reqUpdatelevel=`echo $minlevel | sed 's/^\([0-9]*\)UL\([0-9]*\)$/\2/'`
	
	  if [[ $currVersion -eq $reqVersion && $currUpdatelevel -ge $reqUpdatelevel ]] ; then
            echo "SUCCESS"
	  else
	    echo "FAIL"
	  fi
	
	fi
}	

#
# Objective: Retrieve Linux distribution and release 
# Usage: getLinuxVer
#        
# Returns:
#	Example: "Oracle Linux 5UL9"
#
function getLinuxVer() {

	rpmRelease=`rpm -qf /etc/redhat-release`
	distribution=""
	
	if [[ :${rpmRelease:0:7}: == :redhat-: ]] ; then
	  distribution="Redhat"
	elif [[ :${rpmRelease:0:11}: == :enterprise-: ||
	        :${rpmRelease:0:12}: == :oraclelinux-: ]] ; then
	  distribution="Oracle"
	fi
	
	redhatRelease=`sed 's/^[a-zA-Z[:blank:]]*\([0-9]*\)\.\([0-9]\).*/\1UL\2/' /etc/redhat-release`
	
	echo "${distribution} Linux ${redhatRelease}"
}

#
# Objective: Retrieve Linux distribution 
# Usage: getLinuxDist
#        
# Returns:
#	Example: "Oracle"
#
function getLinuxDist() {

        getLinuxVer | sed 's/^\(.*\)[[:blank:]]Linux[[:blank:]]\(.*\)$/\1/'
}

#
# Objective: Retrieve Linux release 
# Usage: getLinuxRel
#        
# Returns:
#	Example: "5UL9"
#
function getLinuxRel() {

        getLinuxVer | sed 's/^\(.*\)[[:blank:]]Linux[[:blank:]]\(.*\)$/\2/'
}

#
# Objective: Compare release numbers
#            Original code at
#            http://stackoverflow.com/questions/4023830/bash-how-compare-two-strings-in-version-format
# Usage: compareVersion {versionNum1} {versionNum2}
#        version number consists of multiple decimal values concatenated by dots (.)
# Returns:
# 	0 	if versionNum1 equals to versionNum2
#	1	if versionNum1 is higer than versionNum2
#       2       if versionNum1 is lower than versionNum2
#
verComp () {
    # Equal based on string compare
    if [[ "$1" == "$2" ]]
    then
	echo "0"
        return 0
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    # Append zeros to ver1 until length is equal to ver2
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    
    # loop through the version number segments separated by a dot
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        # compare decimal value
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo "1"
            return 1
        fi
        # compare decimal value
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo "2"
            return 2
        fi
    done

    echo "0"
    return 0
}


#
# Objective: Check if minimal version of package is available
# Usage: checkLib {pkg_name} {pkg_version} {pkg_release} {pkg_architecture}
#
# Returns:
#	-1	package not found
#	0	package found with same or higher version and release number
#
function checkLib() {
  local resultcode=-2
  # Using RPM naming standards
  # http://www.rpm.org/max-rpm/ch-rpm-file-format.html

  req_pkg_name=$1
  req_pkg_ver=$2
  req_pkg_rel=$3
  req_pkg_arch=$4

  IFS=$' \t\n'
  # http://www.rpm.org/max-rpm/ch-rpm-file-format.html
  if [ -z ${req_pkg_arch} ] ; then
    declare -a curr_rpms=($(rpm -qa --qf "%{NAME}^%{VERSION}^%{RELEASE}^%{ARCH}\n" | grep "${req_pkg_name}^"))
  else
    declare -a curr_rpms=($(rpm -qa --qf "%{NAME}^%{VERSION}^%{RELEASE}^%{ARCH}\n" | grep "${req_pkg_name}^" | grep "${req_pkg_arch}"))
  fi

  echo -e "\n  Package ${req_pkg_name} Ver ${req_pkg_ver} Rel ${req_pkg_rel} Arch ${req_pkg_arch}"

  if [[ ${#curr_rpms[@]} == 0 ]] ;
  then
    curr_rpms+=('\n')
  fi

  for curr_rpm in "${curr_rpms[@]}" ;
  do
 
      IFS="^"
      set -- "$curr_rpm"
      declare -a cur_rpm_details=($*)
      cur_pkg_name=${cur_rpm_details[0]}
      cur_pkg_ver=${cur_rpm_details[1]}
      cur_pkg_rel=${cur_rpm_details[2]}
      cur_pkg_arch=${cur_rpm_details[3]}
      cur_pkg_rel=$(echo ${cur_pkg_rel} | sed 's/^\(.*\)\.el.*$/\1/')

      if [ -z "${cur_pkg_ver}${cur_pkg_rel}" ]; 
      then
        result1="    [FAILED] could not find any installed packages"
        resultcode=-1
      else
        # if release number specified and current version and release >= required version and release
        # or if release number is not specified and current version >= required version
        if [[ ( -n ${req_pkg_rel} && \
		  ( ( "$(verComp ${cur_pkg_ver} ${req_pkg_ver})" == "0"  && $(verComp ${cur_pkg_rel} ${req_pkg_rel}) == "0" ) \
		  || ( "$(verComp ${cur_pkg_ver} ${req_pkg_ver})" == "0"  && $(verComp ${cur_pkg_rel} ${req_pkg_rel}) == "1" ) \
		  || ( "$(verComp ${cur_pkg_ver} ${req_pkg_ver})" == "1" )  ) \
              ) || \
              ( -z ${req_pkg_rel} && \
		   ( ( "$(verComp ${cur_pkg_ver} ${req_pkg_ver})" == "0" ) \
		   || ( "$(verComp ${cur_pkg_ver} ${req_pkg_ver})" == "1" ) ) \
              ) ]]
        then 
          result1="    [PASS] found package\n         Package ${cur_pkg_name} Ver ${cur_pkg_ver} Rel ${cur_pkg_rel} Arch ${cur_pkg_arch}" 
          resultcode=0
        else
	  result1="    [FAIL] package not found\n         Package ${cur_pkg_name} Ver ${cur_pkg_ver} Rel ${cur_pkg_rel} Arch ${cur_pkg_arch}"
	fi
      fi
      echo -e "${result1}"
  done

  return ${resultcode}
}


function usage() {

	scriptname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

	echo -e "\nUsage:\n"
	echo -e "${scriptname} {-x [XMLCONFIGFILE]}"
	echo -e "If -x argument is not used, expected xml config file is {script basename}.xml"
 
	exit

}

# Get the input parameters
while getopts "x:" arg
do
        case $arg in
                x)
                        export xmlfile=${OPTARG}
                ;;

                *)
                        usage
                ;;
        esac
done

# If config file is not supplied as argument use basename of script as config file
if [[ -z ${xmlfile} ]]
then
    scriptname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    xmlfile=${scriptname%%.*}.xml
fi

# Test argument and existance of config file 
if [[ ! -f ${xmlfile} ]]
then
    echo "XML Config file \"${xmlfile}\" does not exist."
    usage
fi

# Validate config file
xmltest=$(xmllint --shell $xmlfile <<<"cat /libsets/libset/text()" 2>&1)

if [ "$?" != "0" ] ; then
  echo "Error parsing $xmlfile" 
  echo $xmltest
  exit 
fi

# Get generic platform information
platform=`uname -p`
osDist=$(getLinuxDist)
osRel=$(getLinuxRel)
kernel=`uname -r`

echo "Platform: ${platform}"
echo "OS Distribution: ${osDist}"
echo "OS Release: ${osRel}"
echo -e "Kernel: ${kernel}\n" 

# Start comparison
test_success=false

IFS=$'\n'
typeset -a libsets=($(xmllint --shell ${xmlfile} <<<"cat /libsets/libset/name/text()" | grep -v "^/ >" | grep -v "^ -------"))
for libset in "${libsets[@]}"
do
  echo -e "\nValidating using libset $libset"

  # Test platform
  tplatform=$(xmllint --shell ${xmlfile} <<<"cat /libsets/libset[name='$libset']/platform/text()" | grep -v "^/ >" | grep -v "^ -------")
  if [ "$platform" == "${tplatform}" ] ; then
    ## Test if OSVersion matches this libset
    IFS=$'\n'
    typeset -a tosversions=($(xmllint --shell ${xmlfile} <<<"cat /libsets/libset[name='$libset']/osversions/osversion/name/text()" | grep -v "^/ >" | grep -v "^ -------"))
    for osversion in "${tosversions[@]}"
    do
      # Test distribution
      tdistr=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/osversions/osversion[name='${osversion}']/distribution/text()" | grep -v "^/ >" | grep -v "^ -------")
      if [ "$osDist" == "${tdistr}" ] ; then
        # Test version and updatelevel
        tlinuxrel=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/osversions/osversion[name='${osversion}']/release/text()" | grep -v "^/ >" | grep -v "^ -------")
        if [ "`testLinuxRel ${tlinuxrel}`" == "SUCCESS" ] ; then
          test_success=true
          echo "  OS Version ${osversion} defined in libset ${libset}"
        fi
      fi
    done

    if [ "${test_success}" == "true" ] ; then
      tkernel=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/kernel/text()" | grep -v "^/ >" | grep -v "^ -------")
      if [ "${kernel:0:${#tkernel}}" == "${tkernel}" ] ; then
        echo "  Platform (${platform}) distribution (${osDist}) release ($tlinuxrel) and kernel version ($tkernel) supported"
        IFS=$'\n'
        typeset -a libids=($(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/libs/lib/id/text()" \
          | grep -v "^/ >" | grep -v "^ -------"))
        for libid in "${libids[@]}"
        do
          tname=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/libs/lib[id='$libid']/name/text()" \
            | grep -v "^/ >" | grep -v "^ -------")
          tversion=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/libs/lib[id='$libid']/version/text()" \
  	    | grep -v "^/ >" | grep -v "^ -------")
          trelease=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/libs/lib[id='$libid']/release/text()" \
	    | grep -v "^/ >" | grep -v "^ -------")
          tarch=$(xmllint --shell $xmlfile <<<"cat /libsets/libset[name='$libset']/libs/lib[id='$libid']/architecture/text()" \
	    | grep -v "^/ >" | grep -v "^ -------")
          checkLib "${tname}" "${tversion}" "${trelease}" "$tarch"
          if [[ "$?" != 0 ]] ; then
            test_success=false
         fi
        done

      fi
    fi
       
  fi

  if [ "${test_success}" == "true" ] ; then
    break
  fi

done

if [ "${test_success}" == "false" ] ; then
  echo -e "\nNo supported combination of OS Version, kernel and/or installed packages"
else 
  echo -e "\nCurrent combination of OS Version, kernel and/or installed packages matches libset $libset"
fi
