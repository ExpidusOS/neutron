foreach name : [ 'argument', 'signal', 'type' ]
  elemental_tests_exec = executable('test-@0@'.format(name), 'test-@0@.c'.format(name),
    dependencies: [elemental_native, check],
    native: true)
  test(name, elemental_tests_exec, protocol: 'tap', suite: ['elemental'])
endforeach
