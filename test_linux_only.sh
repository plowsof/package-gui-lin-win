RUN_ID="3078884796"
GH_KEY="hunter2"
rm -rf clifiles
rm -rf inno
rm -rf dummy
rm -rf uploadme
rm -rf frombuild
rm start-low-graphics-mode.bat
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
cr=$'\r'
tee "start-low-graphics-mode.bat" <<EOF
@echo off$cr
$cr
set QMLSCENE_DEVICE=softwarecontext$cr
$cr
start /b monero-wallet-gui.exe$cr
EOF
sha256sum start-low-graphics-mode.bat
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
-e '11 cTouchDate=none \nTouchTime=none' \
-e '74 cSource: "ReadMe.htm"; DestDir: "{app}"; Flags: ignoreversion' ${inno_file}
for f in "utils/*"; do
  cp $f "inno/installers/windows"
done
HOMEDIR="$(pwd)"
##
## Get time offset
##
offset=$(date +%z | sed 's/0//g')
stamp=$(stat -c '%y' frombuild/monero-wallet-gui.exe) 
echo "offset is $offset"
corrected_stamp=$(date -d"${stamp} ${offset} hours" +"%Y%m%d%H%M.%S")

echo "The timestamp is ${corrected_stamp}\n**************************"
for f in "inno/installers/windows/*" "inno/installers/windows/**/*" "inno/installers/windows/**/**/*"; do
  echo $f
  touch -t "${corrected_stamp}" $f
done

ls -la inno/installers/windows/*
wine inno/installers/windows/ISCC.exe inno/installers/windows/Monero.iss
mkdir uploadme
mv  inno/installers/windows/Output/mysetup.exe "uploadme/monero-gui-install-win-x64-${TAG}.exe"
sha256sum uploadme/*
