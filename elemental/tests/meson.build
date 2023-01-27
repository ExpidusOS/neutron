elemental_tests_exec = executable('elemental-tests', 'tests.c',
  dependencies: [elemental_native, check],
  native: true)
test('elemental', elemental_tests_exec, protocol: 'tap')
