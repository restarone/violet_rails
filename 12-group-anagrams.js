/**
 * Group Anagrams - LeetCode #49
 * Difficulty: Medium
 *
 * Given an array of strings, group the anagrams together.
 * An anagram is a word formed by rearranging the letters of another word.
 *
 * Time Complexity: O(N * K log K) where N = number of words, K = max word length
 * Space Complexity: O(N * K)
 */

/**
 * Approach 1: Sorted String as Key
 * Most intuitive and commonly used approach
 */
function groupAnagrams(words) {
    const map = new Map();

    for (const word of words) {
        // Create signature by sorting the word's characters
        const signature = word.split('').sort().join('');

        // Group words by their signature
        if (!map.has(signature)) {
            map.set(signature, []);
        }
        map.get(signature).push(word);
    }

    // Return all groups as an array of arrays
    return Array.from(map.values());
}

/**
 * Approach 2: Character Count as Key
 * Slightly faster when K is large (avoids sorting)
 * Time Complexity: O(N * K)
 */
function groupAnagramsCharCount(words) {
    const map = new Map();

    for (const word of words) {
        // Create character frequency array
        const count = new Array(26).fill(0);
        for (const char of word) {
            const index = char.charCodeAt(0) - 'a'.charCodeAt(0);
            count[index]++;
        }

        // Use frequency array as signature (converted to string)
        const signature = count.join(',');

        if (!map.has(signature)) {
            map.set(signature, []);
        }
        map.get(signature).push(word);
    }

    return Array.from(map.values());
}

/**
 * Approach 3: Prime Number Multiplication
 * Creative approach using unique prime factorization
 * Note: Can overflow for long strings!
 */
function groupAnagramsPrime(words) {
    // First 26 prime numbers for a-z
    const primes = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
        31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
        73, 79, 83, 89, 97, 101
    ];

    const map = new Map();

    for (const word of words) {
        // Calculate product of primes for each character
        let signature = 1;
        for (const char of word) {
            const index = char.charCodeAt(0) - 'a'.charCodeAt(0);
            signature *= primes[index];
        }

        if (!map.has(signature)) {
            map.set(signature, []);
        }
        map.get(signature).push(word);
    }

    return Array.from(map.values());
}

/**
 * Bonus: Case-Insensitive Grouping
 * Groups anagrams regardless of case
 */
function groupAnagramsCaseInsensitive(words) {
    const map = new Map();

    for (const word of words) {
        // Create signature from lowercase version
        const signature = word.toLowerCase().split('').sort().join('');

        if (!map.has(signature)) {
            map.set(signature, []);
        }
        // Store original word (preserves case)
        map.get(signature).push(word);
    }

    return Array.from(map.values());
}

// ============================================================================
// HELPER FUNCTIONS & UTILITIES
// ============================================================================

/**
 * Naive approach - for comparison
 * Time: O(N² * K)
 */
function groupAnagramsNaive(words) {
    const result = [];
    const used = new Set();

    function areAnagrams(str1, str2) {
        if (str1.length !== str2.length) return false;
        const sorted1 = str1.split('').sort().join('');
        const sorted2 = str2.split('').sort().join('');
        return sorted1 === sorted2;
    }

    for (let i = 0; i < words.length; i++) {
        if (used.has(i)) continue;

        const group = [words[i]];
        used.add(i);

        for (let j = i + 1; j < words.length; j++) {
            if (!used.has(j) && areAnagrams(words[i], words[j])) {
                group.push(words[j]);
                used.add(j);
            }
        }

        result.push(group);
    }

    return result;
}

/**
 * Pretty print the grouped anagrams
 */
function printGroups(groups) {
    console.log('Grouped Anagrams:');
    groups.forEach((group, index) => {
        console.log(`  Group ${index + 1}: [${group.map(w => `"${w}"`).join(', ')}]`);
    });
    console.log();
}

/**
 * Performance comparison utility
 */
function comparePerformance(words) {
    console.log(`Testing with ${words.length} words...\n`);

    // Sorted approach
    console.time('Sorted Signature');
    const result1 = groupAnagrams(words);
    console.timeEnd('Sorted Signature');

    // Character count approach
    console.time('Character Count');
    const result2 = groupAnagramsCharCount(words);
    console.timeEnd('Character Count');

    // Prime approach (if words are short enough)
    if (words.every(w => w.length < 10)) {
        console.time('Prime Number');
        const result3 = groupAnagramsPrime(words);
        console.timeEnd('Prime Number');
    }

    console.log();
    return result1;
}

// ============================================================================
// TEST CASES
// ============================================================================

function runTests() {
    console.log('========================================');
    console.log('GROUP ANAGRAMS - TEST SUITE');
    console.log('========================================\n');

    // Test 1: Basic example
    console.log('Test 1: Basic Example');
    const test1 = ["eat", "tea", "tan", "ate", "nat", "bat"];
    printGroups(groupAnagrams(test1));

    // Test 2: Empty input
    console.log('Test 2: Empty Input');
    const test2 = [];
    console.log('Result:', groupAnagrams(test2));
    console.log();

    // Test 3: Single word
    console.log('Test 3: Single Word');
    const test3 = ["a"];
    console.log('Result:', groupAnagrams(test3));
    console.log();

    // Test 4: No anagrams
    console.log('Test 4: No Anagrams');
    const test4 = ["abc", "def", "ghi"];
    printGroups(groupAnagrams(test4));

    // Test 5: All anagrams
    console.log('Test 5: All Anagrams');
    const test5 = ["eat", "tea", "ate", "eta"];
    printGroups(groupAnagrams(test5));

    // Test 6: Empty strings
    console.log('Test 6: Empty Strings');
    const test6 = ["", "", "a"];
    printGroups(groupAnagrams(test6));

    // Test 7: Case insensitive
    console.log('Test 7: Case Insensitive');
    const test7 = ["Eat", "tea", "TAN", "ate", "NAT", "bat"];
    printGroups(groupAnagramsCaseInsensitive(test7));

    // Performance Test
    console.log('========================================');
    console.log('PERFORMANCE COMPARISON');
    console.log('========================================\n');

    const largeTest = [];
    const words = ["listen", "silent", "enlist", "eat", "tea", "ate", "hello", "world"];
    for (let i = 0; i < 100; i++) {
        largeTest.push(...words);
    }

    comparePerformance(largeTest);

    console.log('========================================');
    console.log('ALL TESTS COMPLETED!');
    console.log('========================================');
}

// ============================================================================
// INTERACTIVE EXAMPLES
// ============================================================================

/**
 * Step-by-step walkthrough with logging
 */
function visualizeExecution(words) {
    console.log('\n🎬 VISUALIZING GROUP ANAGRAMS EXECUTION\n');
    console.log('Input:', words);
    console.log('\n--- Processing ---\n');

    const map = new Map();

    words.forEach((word, index) => {
        const signature = word.split('').sort().join('');

        console.log(`Step ${index + 1}: Processing "${word}"`);
        console.log(`  Signature: "${signature}"`);

        if (!map.has(signature)) {
            map.set(signature, []);
            console.log(`  → Created new group for "${signature}"`);
        } else {
            console.log(`  → Adding to existing group for "${signature}"`);
        }

        map.get(signature).push(word);
        console.log(`  Current groups:`, JSON.stringify(Array.from(map.entries())));
        console.log();
    });

    const result = Array.from(map.values());
    console.log('--- Final Result ---');
    printGroups(result);

    return result;
}

// ============================================================================
// EXPORTS (for use in other files or as module)
// ============================================================================

if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        groupAnagrams,
        groupAnagramsCharCount,
        groupAnagramsPrime,
        groupAnagramsCaseInsensitive,
        groupAnagramsNaive,
        visualizeExecution,
        printGroups,
        comparePerformance,
        runTests
    };
}

// ============================================================================
// RUN TESTS (if executed directly)
// ============================================================================

if (require.main === module) {
    runTests();

    // Run visualization example
    console.log('\n\n');
    visualizeExecution(["eat", "tea", "tan", "ate", "nat", "bat"]);
}
