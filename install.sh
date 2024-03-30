sudo sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list
sudo apt-get update && sudo apt-get build-dep -y neovim
git clone https://github.com/zeertzjq/neovim/ -b on-key-typed /tmp/neovim
cd /tmp/neovim
cmake -S cmake.deps -B .deps -G 'Unix Makefiles' -D CMAKE_BUILD_TYPE=RelWithDebInfo --fresh
cmake --build .deps -j8
cmake -B build -G 'Unix Makefiles' -D CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j 8
sudo cmake --build build -t install
