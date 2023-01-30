foreach name : [ 'shimmy' ]
  shimmy_tests_exec = executable('test-@0@'.format(name), 'test-@0@.c'.format(name),
    dependencies: [shimmy, check])
  test(name, shimmy_tests_exec, protocol: 'tap', suite: ['shimmy'])
endforeach
