foreach name : [ 'argument', 'signal', 'type' ]
  elemental_tests_exec = executable('test-@0@'.format(name), 'test-@0@.c'.format(name),
    dependencies: [elemental, check])
  test(name, elemental_tests_exec, protocol: 'tap', suite: ['elemental'])
endforeach
