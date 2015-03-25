cmake_minimum_required(VERSION 2.8.12)

include("$ENV{CMAKEPP_PATH}")


project(density C)

set(src_directory "src")
set(spookyhash_directory "${src_directory}/spookyhash")
set(spookyhash_src_directory "${spookyhash_directory}/src")


set(cflags -Ofast -fomit-frame-pointer -w -flto -std=c99)

glob("${src_directory}/*.[ch]")
ans(density_src)

glob("${spookyhash_src_directory}/*.[ch]")
ans(spookyhash_src)

## submodule not initialized
if(NOT spookyhash_src)
  git(submodule update --init --recursive)
endif()


add_library(spookyhash ${spookyhash_src})
target_include_directories(spookyhash PUBLIC ${spookyhash_src_directory})

if(MSVC)
  target_include_directories(spookyhash PUBLIC "src/msvc")
  target_compile_definitions(spookyhash PUBLIC restrict=)
endif()

add_library(density ${density_src})
target_include_directories(density PUBLIC ${src_directory})
target_link_libraries(density spookyhash)



