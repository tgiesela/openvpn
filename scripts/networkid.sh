D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
OPENVPN_IP=$1 
OPENVPN_MASK=$2 
NEWMASK=""
IFS="."
arrip=($OPENVPN_IP)
arrmask=($OPENVPN_MASK)
unset IFS

for i in {0..3}; do
    NEWMASK=${NEWMASK}${D2B[${arrmask[i]}]}
    if [ ${arrmask[i]} == "0" ]; then
	((arrip[i] = 0))
    fi
done

i=${#NEWMASK}-1
while [ i > 0 ] && [ "${NEWMASK:$i:1}" == "0" ] ; do
   (( i -= 1 ))
done
((i += 1))

NEWIP=${arrip[0]}.${arrip[1]}.${arrip[2]}.${arrip[3]}
echo ${NEWIP}/${i} 
