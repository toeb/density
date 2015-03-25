cmake_minimum_required(VERSION 2.8.12)

## TODOs
## * add cmakepp in a more reliable fashion (ie don't just depend on its existance)
## * add compiler flags
## * add cmakepp package file


## include cmakepp
include("$ENV{CMAKEPP_PATH}")

## set project language to C
project(density C)


set(density_src_directory "src")
set(spookyhash_directory "${density_src_directory}/spookyhash")
set(spookyhash_src_directory "${spookyhash_directory}/src")

## gather all source files for density
glob("${density_src_directory}/*.[ch]")
ans(density_src)

## gather all source files for spookyhash
glob("${spookyhash_src_directory}/*.[ch]")
ans(spookyhash_src)

## submodule not initialized update init recursive and gather source again
if(NOT spookyhash_src)
  git(submodule update --init --recursive)
  glob("${spookyhash_src_directory}/*.[ch]")
  ans(spookyhash_src)
endif()


## add spookyhash target
add_library(spookyhash ${spookyhash_src})
target_include_directories(spookyhash PUBLIC ${spookyhash_src_directory})
if(MSVC)
  target_include_directories(spookyhash PUBLIC "src/msvc")
  target_compile_definitions(spookyhash PUBLIC restrict=)
endif()

## add density library
add_library(density ${density_src})
target_include_directories(density PUBLIC ${density_src_directory})
target_link_libraries(density spookyhash)



