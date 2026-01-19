# Group Anagrams: Sorting Words Into Labeled Boxes

![Difficulty: Medium](https://img.shields.io/badge/Difficulty-Medium-yellow)
![Time: O(N*K log K)](https://img.shields.io/badge/Time-O(N*K%20log%20K)-blue)
![Space: O(N*K)](https://img.shields.io/badge/Space-O(N*K)-green)

---

## 🎯 Problem Hook

**Real-World Analogy:** Imagine you're organizing a messy pile of scrabble tiles. You want to group together all the sets of tiles that can spell the same words (just scrambled). Instead of comparing every word to every other word (exhausting!), you could create a "signature" for each word - like sorting its letters alphabetically - and then just group words with matching signatures!

**The Challenge:** Given an array of strings, group the anagrams together. An anagram is a word formed by rearranging the letters of another word.

```
Input: ["eat","tea","tan","ate","nat","bat"]
Output: [["eat","tea","ate"],["tan","nat"],["bat"]]
```

---

## 📚 Learning Goal

**You will learn:**
- How to create "signatures" to identify anagrams efficiently
- Why hash maps are perfect for grouping related items
- How to transform an O(N²) comparison problem into O(N*K log K)
- The trade-off between space and time complexity

---

## 🧠 Prerequisites

**Concepts you should know:**

| Concept | Why It Matters |
|---------|---------------|
| 🔤 **Strings** | Working with character manipulation |
| 📊 **Arrays** | Iterating through collections |
| 🗺️ **Hash Maps** | Grouping items by keys |
| ✓ **Valid Anagram** | Understanding anagram detection |

**Quick Refresher:** Two words are anagrams if they contain the exact same letters in different orders. "listen" and "silent" are anagrams!

---

## 🎬 Algorithm Walkthrough

### **Phase 1: Understanding the Problem**

Let's visualize our input:
```
words = ["eat", "tea", "tan", "ate", "nat", "bat"]

What we want:
["eat", "tea", "ate"] → all have letters {a, e, t}
["tan", "nat"]        → all have letters {a, n, t}
["bat"]               → has letters {a, b, t}
```

### **Phase 2: The Naive Approach** ❌

```javascript
// DON'T DO THIS - O(N² * K) time complexity
function groupAnagramsNaive(words) {
    const result = [];
    const used = new Set();

    for (let i = 0; i < words.length; i++) {
        if (used.has(i)) continue;

        const group = [words[i]];
        used.add(i);

        // Compare with every other word
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
```

**Why this is slow:** For each word, we compare it with every other word. That's N² comparisons!

### **Phase 3: The Key Insight** 💡

**Question:** How can we identify anagrams without comparing every pair?

**Answer:** Create a unique "signature" for each word!

Two approaches:
1. **Sort the letters** → "eat" becomes "aet"
2. **Count characters** → "eat" becomes "a1e1t1"

Both anagrams will have the SAME signature!

### **Phase 4: Optimal Solution - Sorted Signature**

```javascript
function groupAnagrams(words) {
    // Step 1: Create a hash map to store groups
    const map = new Map();

    // Step 2: Process each word
    for (const word of words) {
        // Step 3: Create signature by sorting letters
        const signature = word.split('').sort().join('');

        // Step 4: Add word to its signature's group
        if (!map.has(signature)) {
            map.set(signature, []);
        }
        map.get(signature).push(word);
    }

    // Step 5: Return all groups as array
    return Array.from(map.values());
}
```

**Visual Execution:**

```
Processing "eat":
  signature = "aet"
  map = { "aet": ["eat"] }

Processing "tea":
  signature = "aet" (same as "eat"!)
  map = { "aet": ["eat", "tea"] }

Processing "tan":
  signature = "ant"
  map = { "aet": ["eat", "tea"], "ant": ["tan"] }

Processing "ate":
  signature = "aet" (joins first group!)
  map = { "aet": ["eat", "tea", "ate"], "ant": ["tan"] }

Processing "nat":
  signature = "ant" (joins second group!)
  map = { "aet": ["eat", "tea", "ate"], "ant": ["tan", "nat"] }

Processing "bat":
  signature = "abt"
  map = { "aet": ["eat", "tea", "ate"], "ant": ["tan", "nat"], "abt": ["bat"] }
```

### **Phase 5: Alternative - Character Count Signature**

For cases where sorting is expensive, use character frequency:

```javascript
function groupAnagramsCharCount(words) {
    const map = new Map();

    for (const word of words) {
        // Create signature using character counts
        const count = new Array(26).fill(0);
        for (const char of word) {
            count[char.charCodeAt(0) - 'a'.charCodeAt(0)]++;
        }
        const signature = count.join(',');

        if (!map.has(signature)) {
            map.set(signature, []);
        }
        map.get(signature).push(word);
    }

    return Array.from(map.values());
}
```

**Example signature for "eat":**
```
e=1, a=1, t=1
signature = "1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0"
           [a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z]
```

---

## 🔑 Key Insights

### **Insight 1: Signature Strategy**
Instead of comparing every word pair (O(N²)), we create ONE signature per word and group by signature (O(N)).

```
❌ Naive: Compare all pairs
   eat vs tea ✓
   eat vs tan ✗
   eat vs ate ✓
   tea vs tan ✗
   tea vs ate ✓
   tan vs ate ✗
   ... N² comparisons!

✅ Optimal: Create signatures
   eat → "aet" → group 1
   tea → "aet" → group 1
   tan → "ant" → group 2
   ate → "aet" → group 1
   ... N operations!
```

### **Insight 2: Hash Map = O(1) Grouping**
Hash maps let us:
- Check if a signature exists: O(1)
- Add to a group: O(1)
- Retrieve groups: O(1)

### **Insight 3: Time Complexity Trade-offs**

| Approach | Time | Space | When to Use |
|----------|------|-------|-------------|
| Sorted Signature | O(N * K log K) | O(N*K) | Default choice, simple |
| Char Count | O(N * K) | O(N*K) | When K is very large |
| Naive Comparison | O(N² * K) | O(1) | Never! |

Where:
- **N** = number of words
- **K** = length of longest word

### **Insight 4: Space for Time**
We use O(N*K) space to store:
- The hash map keys (signatures)
- The hash map values (grouped words)

But we get much faster grouping in return!

---

## ✋ Check Your Understanding

### **Question 1:** What gets stored as the hash map KEY?
<details>
<summary>Click to reveal</summary>

**Answer:** The signature (sorted letters or character count)

Example: For "eat", the key is "aet"
</details>

### **Question 2:** What gets stored as the hash map VALUE?
<details>
<summary>Click to reveal</summary>

**Answer:** An array of all words with that signature

Example: For key "aet", value is ["eat", "tea", "ate"]
</details>

### **Question 3:** Why is sorting "aet" useful?
<details>
<summary>Click to reveal</summary>

**Answer:** Because "eat", "tea", and "ate" ALL become "aet" when sorted. This creates a unique identifier that all anagrams share!
</details>

### **Question 4:** What if we have a word with no anagrams?
<details>
<summary>Click to reveal</summary>

**Answer:** It gets its own group with just one word. Example: "bat" → signature "abt" → [["bat"]]
</details>

---

## 💪 Practice Challenge

### **Variation Problem: Group Anagrams with Case Insensitivity**

**Task:** Modify the solution to treat uppercase and lowercase as the same.

```javascript
Input: ["Eat", "tea", "TAN", "ate", "NAT", "bat"]
Output: [["Eat", "tea", "ate"], ["TAN", "NAT"], ["bat"]]
```

**Hint:** Convert to lowercase before creating the signature, but keep original words!

<details>
<summary>Solution</summary>

```javascript
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
```
</details>

---

## 📋 Summary & Connections

### **Key Takeaway Card**

```
┌─────────────────────────────────────────────────┐
│  GROUP ANAGRAMS PATTERN                         │
├─────────────────────────────────────────────────┤
│  ✓ Create unique signatures for similar items   │
│  ✓ Use hash maps to group by signature          │
│  ✓ Trade space for time (O(N*K) space saves     │
│    us from O(N²) comparisons)                   │
│  ✓ Sorting is a common signature technique      │
└─────────────────────────────────────────────────┘
```

### **Related Algorithms**

```
Prerequisites:
  ← Valid Anagram (simpler version)

Similar Patterns:
  → Group Shifted Strings (similar grouping logic)
  → Find Duplicate Subtrees (signature concept)
  → Group Array Elements (hash map grouping)

Next Steps:
  → Top K Frequent Elements (frequency + hash maps)
  → Longest Consecutive Sequence (hash set usage)
```

---

## 🎨 Visual Design Elements

### **Animation Storyboard** (for video/interactive version)

**Frame 1-2: Hook (10%)**
- Show messy pile of word cards
- "How do we organize these efficiently?"

**Frame 3-4: Naive Approach (15%)**
- Animate comparing each pair
- Show time counter going up (slow!)

**Frame 5-8: Signature Generation (25%)**
- Take one word: "EAT"
- Split letters: [E, A, T]
- Sort: [A, E, T]
- Join: "AET"
- Highlight: This is the signature!

**Frame 9-12: Hash Map Grouping (35%)**
- Show hash map structure
- Add words one by one
- Each finds its signature's bucket
- Groups form automatically

**Frame 13-14: Result (10%)**
- Show final grouped arrays
- Celebrate efficiency!

**Frame 15: Summary (5%)**
- Key insights display

### **Color Palette**

```
🟦 Primary (Hash Map):     #3B82F6 (blue)
🟩 Secondary (Groups):     #10B981 (green)
🟨 Accent (Signatures):    #F59E0B (amber)
⬜ Background:             #F9FAFB (light gray)
⬛ Text:                   #111827 (dark gray)
```

---

## 📊 Complexity Analysis

### **Sorted Signature Approach**

```javascript
function groupAnagrams(words) {                  // N words
    const map = new Map();                       // O(1) space init

    for (const word of words) {                  // O(N) loop
        const signature = word
            .split('')                           // O(K)
            .sort()                              // O(K log K)
            .join('');                           // O(K)

        if (!map.has(signature)) {               // O(1) lookup
            map.set(signature, []);              // O(1) insert
        }
        map.get(signature).push(word);           // O(1) append
    }

    return Array.from(map.values());             // O(N) convert
}
```

**Time Complexity:** O(N * K log K)
- N = number of words
- K = average word length
- Dominant operation: sorting each word

**Space Complexity:** O(N * K)
- Storing all words in hash map groups
- Storing signatures as keys

### **Character Count Approach**

**Time Complexity:** O(N * K)
- Counting characters is O(K) vs sorting O(K log K)

**Space Complexity:** O(N * K)
- Same storage requirements

---

## 🧪 Test Cases

```javascript
// Test 1: Basic example
console.log(groupAnagrams(["eat","tea","tan","ate","nat","bat"]));
// Expected: [["eat","tea","ate"],["tan","nat"],["bat"]]

// Test 2: Empty input
console.log(groupAnagrams([]));
// Expected: []

// Test 3: Single word
console.log(groupAnagrams(["a"]));
// Expected: [["a"]]

// Test 4: No anagrams
console.log(groupAnagrams(["abc", "def", "ghi"]));
// Expected: [["abc"], ["def"], ["ghi"]]

// Test 5: All anagrams
console.log(groupAnagrams(["eat", "tea", "ate", "eta"]));
// Expected: [["eat","tea","ate","eta"]]

// Test 6: Empty strings
console.log(groupAnagrams(["", "", "a"]));
// Expected: [["",""], ["a"]]
```

---

## 💡 Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting to initialize groups
```javascript
// WRONG
map.get(signature).push(word); // Error if signature not in map!

// RIGHT
if (!map.has(signature)) {
    map.set(signature, []);
}
map.get(signature).push(word);
```

### ❌ Mistake 2: Modifying the original word
```javascript
// WRONG
const signature = word.sort(); // word is a string, not array!

// RIGHT
const signature = word.split('').sort().join('');
```

### ❌ Mistake 3: Case sensitivity
```javascript
// "Eat" and "eat" would be treated as different!
// Use .toLowerCase() if needed
```

### ❌ Mistake 4: Using array as hash key
```javascript
// WRONG - arrays are compared by reference
const count = [1, 0, 1];
map.set(count, [word]); // Each array is unique!

// RIGHT - convert to string
const signature = count.join(',');
map.set(signature, [word]);
```

---

## 🚀 Real-World Applications

1. **Spell Checkers:** Group words by their letters to suggest corrections
2. **Search Engines:** Find pages with similar content (word signatures)
3. **Plagiarism Detection:** Identify documents with rearranged text
4. **DNA Sequencing:** Group similar genetic sequences
5. **E-commerce:** Group products with same features (just reordered)

---

## 📚 Additional Resources

- [LeetCode Problem #49](https://leetcode.com/problems/group-anagrams/)
- [Video: Group Anagrams Explained](https://www.youtube.com/results?search_query=group+anagrams)
- [Hash Map Time Complexity Deep Dive](https://stackoverflow.com/questions/9214353/hash-table-runtime-complexity-insert-search-and-delete)

---

**Estimated Learning Time:** 45-60 minutes
**Practice Time:** 30-45 minutes
**Total Mastery:** 2-3 hours

---

*Built with 💜 following Gagne's 9 Events of Instruction*
*Cognitive Load: Medium | Visual Complexity: Medium*
