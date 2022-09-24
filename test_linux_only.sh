##
## expects this repo to be cloned next to it utils/ folder
##
RUN_ID="3078884796"
GH_KEY="hunter2"
rm -rf clifiles
rm -rf inno
rm -rf dummy
rm -rf uploadme
rm -rf frombuild
rm monero-wallet-gui.AppImage
rm docker-windows-static
rm *pdf
rm *.zip
rm *.bz2

# Download docker-windows-static
download_artifact(){ run_id=$1 get_name=$2 save_as=$3 gh_key=$4
	workflow_run=$(curl \
	  -H "Accept: application/vnd.github+json" \
	  https://api.github.com/repos/monero-project/monero-gui/actions/runs/${run_id}/artifacts)
	num=0
	for artifact_name in $(echo ${workflow_run} | jq -r '.artifacts[].name'); do
		if [[ "${artifact_name}" == "${get_name}" ]]; then
			URL=$(echo ${workflow_run} | jq -r ".artifacts[${num}].archive_download_url")
			TAG=$(echo ${workflow_run} | jq -r ".artifacts[${num}].workflow_run.head_branch")
			echo "DONE"
			break
		fi
		((num+=1))
	done
	curl \
	  -H "Accept: application/vnd.github+json" \
	  -H "Authorization: token ${gh_key}" \
	  -L -o "${save_as}" \
	  "${URL}"

	echo $URL
}

download_artifact $RUN_ID "docker-windows-static" "docker-windows-static" "${GH_KEY}"

#Extract static files to frombuild
unzip "docker-windows-static" -d frombuild

# Download CLI/PDF file(s)

wget -q "https://gui.xmr.pm/files/cli/${TAG}/monero-win-x64-${TAG}.zip" 
wget -q "https://github.com/monero-ecosystem/monero-GUI-guide/releases/download/v1.9/monero-gui-wallet-guide.pdf" 

unzip "monero-win-x64-${TAG}.zip" -d clifiles

# Create lowgfx bat file with heredoc

#tee "start-low-graphics-mode.bat" <<EOF
#@echo off
#
#set QMLSCENE_DEVICE=softwarecontext
#
#start /b monero-wallet-gui.exe
#EOF

mkdir -p "dummy/monero-gui-${TAG}/extras"
HEAD="clifiles/monero-x86_64-w64-mingw32-${TAG}"
OUT="dummy/monero-gui-${TAG}"

echo "HEAD is ${HEAD}"
license="${HEAD}/LICENSE"
monerod="${HEAD}/monerod.exe"
echo "Hello"
mv $license "${OUT}/"
mv $monerod "${OUT}/"
echo "123"
readme="${HEAD}/README.md"; rm "${readme}"
anon="${HEAD}/ANONYMITY_NETWORKS.md"; rm "${anon}"

dest="dummy/monero-gui-${TAG}"

cp monero-gui-wallet-guide.pdf "${dest}/"
cp frombuild/monero-wallet-gui.exe "${dest}/"
cp utils/opengl32sw.dll "${dest}/"
cp start-low-graphics-mode.bat "${dest}/"
echo "233444"
ls ${HEAD}
for f in "${HEAD}/*"; do
  echo "$f"
  cp $f "dummy/monero-gui-${TAG}/extras"
done
echo "reeeee"
dest="dummy/monero-gui-${TAG}"
mkdir inno; cd inno
git init
git remote add -f origin https://github.com/monero-project/monero-gui
git sparse-checkout init
git sparse-checkout set "installers/windows"
git pull origin master
mkdir -p installers/windows/bin

cd ..

for f in "${dest}/*"; do
  cp -r $f "inno/installers/windows/bin"
done

strip_v="${TAG:1}"
inno_file='inno/installers/windows/Monero.iss'

# mistake in v0.18.1.1. to reproduce hash use line 13
# -e '13 cTouchDate=none \nTouchTime=none' \

sed -i \
-e "4 c#define GuiVersion \"${strip_v}\"" \
-e '13 cTouchDate=none \nTouchTime=none' \
-e '74 cSource: "ReadMe.htm"; DestDir: "{app}"; Flags: ignoreversion' ${inno_file}

for f in "utils/*"; do
  cp $f "inno/installers/windows"
done

HOMEDIR="$(pwd)"

stamp=$(stat -c '%y' frombuild/monero-wallet-gui.exe) 

corrected_stamp=$(date -d"${stamp} +1 hours" +"%Y%m%d%H%M.%S")

for f in "inno/installers/windows/*" "inno/installers/windows/**/*" "inno/installers/windows/**/**/*"; do
  echo $f
  touch -t "${corrected_stamp}" $f
done

wine inno/installers/windows/ISCC.exe inno/installers/windows/Monero.iss


mkdir uploadme
mv  inno/installers/windows/Output/mysetup.exe "uploadme/monero-gui-install-win-x64-${TAG}.exe"

sha256sum uploadme/*

cd $HOMEDIR

for f in "dummy/monero-gui-${TAG}/*" "dummy/monero-gui-${TAG}/**/*"; do
  echo $f
  touch -t "${corrected_stamp}" $f
done

cd dummy

touch -t "${corrected_stamp}" "monero-gui-${TAG}"

TZ=UTC zip -r -oX "monero-gui-win-x64-${TAG}.zip" "monero-gui-${TAG}/"

mv "monero-gui-win-x64-${TAG}.zip" ../uploadme/


rm -rf dummy

wget -q "https://github.com/monero-ecosystem/monero-GUI-guide/releases/download/v1.9/monero-gui-wallet-guide.pdf" 
mkdir dummy
download_artifact $RUN_ID "docker-linux-static" "docker-linux-static" "${GH_KEY}"
unzip "docker-linux-static" -d frombuild

wget -q "https://gui.xmr.pm/files/cli/${TAG}/monero-linux-x64-${TAG}.tar.bz2"

cat <<EOF >> monero-wallet-gui.AppImage
./monero-wallet-gui
EOF
          
chmod -R 755 monero-wallet-gui.AppImage
chmod -R 755 frombuild/monero-wallet-gui #???
          
tar -xvf "monero-linux-x64-${TAG}.tar.bz2"

mkdir -p monero-gui-${TAG}/extras

HEAD=monero-x86_64-linux-gnu-

mv ${HEAD}${TAG}/LICENSE monero-gui-${TAG}/.
mv ${HEAD}${TAG}/monerod monero-gui-${TAG}/.
rm ${HEAD}${TAG}/README.md
rm ${HEAD}${TAG}/ANONYMITY_NETWORKS.md

cp monero-gui-wallet-guide.pdf monero-gui-${TAG}/.
cp frombuild/monero-wallet-gui monero-gui-${TAG}/.
cp monero-wallet-gui.AppImage monero-gui-${TAG}/.

chmod -R 644 monero-gui-${TAG}/monero-gui-wallet-guide.pdf 
chmod -R 644 monero-gui-${TAG}/LICENSE

stamp=$(stat -c '%y' frombuild/monero-wallet-gui) 

MTIME_GUI=$(date -d"${stamp}" +"%Y-%m-%d 01:00:00")
#tar: Option --mtime: Treating date '2022-09-18' as 2022-09-18 00:00:00

ls -la 
echo "BEFORE CHMOD"
for filename in ${HEAD}${TAG}/*; do
	chmod -R 755 ${filename} 
	mv ${filename} monero-gui-${TAG}/extras/. 
done

sudo mv monero-gui-${TAG} dummy/

mkdir uploadme
cd dummy
echo "MTIME_GUI = ${MTIME_GUI}"

GZIP=-n tar --sort=name --mtime="${MTIME_GUI}" -cvjSf monero-gui-linux-x64-${TAG}.tar.bz2 monero-gui-${TAG}

cp monero-gui-linux-x64-${TAG}.tar.bz2 ../uploadme/.

cd ..

sha256sum uploadme/*