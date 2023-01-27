elemental_test_exec = executable('elemental-tests', 'tests.c',
  dependencies: [elemental_native, check],
  native: true)
test('elemental', elemental_test_exec, protocol: 'tap')
