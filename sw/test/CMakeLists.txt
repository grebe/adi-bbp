add_executable(
    unit_tests
    test_tx.cc
  )

target_link_libraries(
    unit_tests
    LINK_PUBLIC
    gtest_main
    fft
    )

add_test(
  NAME
    unit
  COMMAND
    ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}/test/unit_tests
  )
