cmake_minimum_required(VERSION 2.8.12)

## TODOs
## * add compiler flags


## include cmakepp
include("cmake/cmakepp.cmake")

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


## add test for density

enable_testing()

glob(tests/*.c)
ans(test_files)
  
## loops through every c file in the tests directory and creates a test 
## for it (naive but effective way of performing tests)
## you can type ctest in your binary dir and it will run all tests.
foreach(test_file ${test_files})
  path_file_name("${test_file}" -we) # get name of file without extension
  ans(test_name)
  ## create executable target
  add_executable("${test_name}" "${test_file}")
  ## link to density lib
  target_link_libraries("${test_name}" "density")
  ## add density include dir and tests dir as include directories
  target_include_directories("${test_name}" PUBLIC "${density_src_directory}" )
  target_include_directories("${test_name}" PUBLIC "${tests}" )
  ## create test (name of test+ name of target to execute)
  add_test("${test_name}" "${test_name}")
endforeach()






