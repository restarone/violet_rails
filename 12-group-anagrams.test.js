/**
 * Test Suite for Group Anagrams
 * Run with: node 12-group-anagrams.test.js
 */

const {
    groupAnagrams,
    groupAnagramsCharCount,
    groupAnagramsPrime,
    groupAnagramsCaseInsensitive,
    groupAnagramsNaive
} = require('./12-group-anagrams.js');

// Test utilities
let testsPassed = 0;
let testsFailed = 0;

function deepEqual(arr1, arr2) {
    if (arr1.length !== arr2.length) return false;

    // Sort both arrays of arrays for comparison
    const sorted1 = arr1.map(inner => [...inner].sort()).sort();
    const sorted2 = arr2.map(inner => [...inner].sort()).sort();

    return JSON.stringify(sorted1) === JSON.stringify(sorted2);
}

function assert(condition, testName) {
    if (condition) {
        console.log(`✅ PASS: ${testName}`);
        testsPassed++;
    } else {
        console.log(`❌ FAIL: ${testName}`);
        testsFailed++;
    }
}

function testFunction(func, input, expected, testName) {
    const result = func(input);
    const passed = deepEqual(result, expected);
    assert(passed, testName);

    if (!passed) {
        console.log('  Expected:', JSON.stringify(expected));
        console.log('  Got:     ', JSON.stringify(result));
    }
}

// Test cases
console.log('========================================');
console.log('GROUP ANAGRAMS - TEST SUITE');
console.log('========================================\n');

console.log('--- Test Suite 1: Basic Functionality ---\n');

// Test 1: Basic example
testFunction(
    groupAnagrams,
    ["eat", "tea", "tan", "ate", "nat", "bat"],
    [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]],
    'Test 1: Basic example with multiple groups'
);

// Test 2: Empty array
testFunction(
    groupAnagrams,
    [],
    [],
    'Test 2: Empty input array'
);

// Test 3: Single word
testFunction(
    groupAnagrams,
    ["a"],
    [["a"]],
    'Test 3: Single word'
);

// Test 4: No anagrams
testFunction(
    groupAnagrams,
    ["abc", "def", "ghi"],
    [["abc"], ["def"], ["ghi"]],
    'Test 4: No anagrams - each word in own group'
);

// Test 5: All anagrams
testFunction(
    groupAnagrams,
    ["eat", "tea", "ate", "eta"],
    [["eat", "tea", "ate", "eta"]],
    'Test 5: All words are anagrams of each other'
);

// Test 6: Empty strings
testFunction(
    groupAnagrams,
    ["", "", "a"],
    [["", ""], ["a"]],
    'Test 6: Including empty strings'
);

// Test 7: Single character words
testFunction(
    groupAnagrams,
    ["a", "b", "a", "c", "b"],
    [["a", "a"], ["b", "b"], ["c"]],
    'Test 7: Single character words'
);

// Test 8: Longer words
testFunction(
    groupAnagrams,
    ["listen", "silent", "enlist", "hello", "world"],
    [["listen", "silent", "enlist"], ["hello"], ["world"]],
    'Test 8: Longer words with anagrams'
);

console.log('\n--- Test Suite 2: Different Approaches ---\n');

// Test 9: Character count approach
testFunction(
    groupAnagramsCharCount,
    ["eat", "tea", "tan", "ate", "nat", "bat"],
    [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]],
    'Test 9: Character count approach'
);

// Test 10: Prime number approach
testFunction(
    groupAnagramsPrime,
    ["eat", "tea", "tan", "ate", "nat", "bat"],
    [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]],
    'Test 10: Prime number approach'
);

// Test 11: Naive approach
testFunction(
    groupAnagramsNaive,
    ["eat", "tea", "tan", "ate", "nat", "bat"],
    [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]],
    'Test 11: Naive approach (comparison)'
);

console.log('\n--- Test Suite 3: Edge Cases ---\n');

// Test 12: Case insensitive
testFunction(
    groupAnagramsCaseInsensitive,
    ["Eat", "tea", "TAN", "ate", "NAT", "bat"],
    [["Eat", "tea", "ate"], ["TAN", "NAT"], ["bat"]],
    'Test 12: Case insensitive grouping'
);

// Test 13: Special characters (if applicable)
testFunction(
    groupAnagrams,
    ["a1b", "1ab", "b1a"],
    [["a1b", "1ab", "b1a"]],
    'Test 13: Words with numbers (treated as anagrams)'
);

// Test 14: Very long anagram group
const longGroup = Array(20).fill("abc");
const expectedLongGroup = [longGroup];
testFunction(
    groupAnagrams,
    longGroup,
    expectedLongGroup,
    'Test 14: Very long anagram group (20 identical words)'
);

// Test 15: Mixed lengths
testFunction(
    groupAnagrams,
    ["ab", "ba", "abc", "bca", "cab", "a"],
    [["ab", "ba"], ["abc", "bca", "cab"], ["a"]],
    'Test 15: Words of different lengths'
);

console.log('\n--- Test Suite 4: Performance Comparison ---\n');

// Generate large test case
function generateLargeTestCase(size) {
    const words = ["listen", "silent", "enlist", "eat", "tea", "ate", "hello", "world", "tan", "nat"];
    const result = [];
    for (let i = 0; i < size; i++) {
        result.push(words[i % words.length]);
    }
    return result;
}

const largeInput = generateLargeTestCase(1000);

console.log(`Testing with ${largeInput.length} words...\n`);

// Test sorted approach
console.time('Sorted Signature Approach');
const result1 = groupAnagrams(largeInput);
console.timeEnd('Sorted Signature Approach');

// Test character count approach
console.time('Character Count Approach');
const result2 = groupAnagramsCharCount(largeInput);
console.timeEnd('Character Count Approach');

// Verify both give same result
assert(
    deepEqual(result1, result2),
    'Performance Test: Both approaches produce same result'
);

console.log('\n--- Test Suite 5: Correctness Verification ---\n');

// Test 16: Verify anagram properties
function verifyAnagramGroups(input, output) {
    // Each output group should contain only anagrams
    for (const group of output) {
        const signature = group[0].split('').sort().join('');
        for (const word of group) {
            const wordSig = word.split('').sort().join('');
            if (signature !== wordSig) {
                return false;
            }
        }
    }

    // All input words should be in output
    const inputSet = new Set(input);
    const outputWords = output.flat();
    const outputSet = new Set(outputWords);

    if (inputSet.size !== outputSet.size) {
        return false;
    }

    for (const word of input) {
        if (!outputSet.has(word)) {
            return false;
        }
    }

    return true;
}

const testInput = ["eat", "tea", "tan", "ate", "nat", "bat"];
const testOutput = groupAnagrams(testInput);
assert(
    verifyAnagramGroups(testInput, testOutput),
    'Test 16: Verify output contains valid anagram groups'
);

console.log('\n========================================');
console.log('TEST SUMMARY');
console.log('========================================');
console.log(`Total Tests: ${testsPassed + testsFailed}`);
console.log(`✅ Passed: ${testsPassed}`);
console.log(`❌ Failed: ${testsFailed}`);
console.log(`Success Rate: ${((testsPassed / (testsPassed + testsFailed)) * 100).toFixed(1)}%`);
console.log('========================================\n');

if (testsFailed === 0) {
    console.log('🎉 All tests passed! Great job!\n');
} else {
    console.log('⚠️  Some tests failed. Please review the failures above.\n');
    process.exit(1);
}
