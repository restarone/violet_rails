# Group Anagrams - Complete Learning Package

![Phase 2: Core Patterns](https://img.shields.io/badge/Phase-2%20Core%20Patterns-blue)
![Priority: 8](https://img.shields.io/badge/Priority-8-green)
![Difficulty: Medium](https://img.shields.io/badge/Difficulty-Medium-yellow)

**Real-World Analogy:** Sorting words into labeled boxes

---

## 📦 Package Contents

This complete learning package includes:

1. **12-group-anagrams.md** - Comprehensive educational content
2. **12-group-anagrams.js** - Implementation with multiple approaches
3. **12-group-anagrams-visualizer.html** - Interactive visual explainer
4. **12-group-anagrams.test.js** - Comprehensive test suite
5. **12-group-anagrams-README.md** - This file (learning guide)

---

## 🎯 Learning Objectives

After completing this module, you will be able to:

✅ Explain how anagrams can be identified using signatures
✅ Implement hash map-based grouping efficiently
✅ Analyze time and space complexity trade-offs
✅ Choose between different signature generation strategies
✅ Apply the pattern to similar grouping problems

---

## 📚 Prerequisites

Before starting, ensure you understand:

- ✓ **Valid Anagram** (Problem #25) - Recommended prerequisite
- ✓ Arrays and string manipulation
- ✓ Hash maps / dictionaries
- ✓ Basic sorting algorithms

---

## 🗺️ Learning Path

### **Step 1: Read the Theory (30 minutes)**

Start with `12-group-anagrams.md` to understand:
- The problem and real-world analogy
- Why the naive approach is inefficient
- How signatures work
- The optimal solution

**Key sections to focus on:**
- Problem Hook (understand the challenge)
- Algorithm Walkthrough (see the solution step-by-step)
- Key Insights (understand WHY it works)

### **Step 2: Interactive Visualization (20 minutes)**

Open `12-group-anagrams-visualizer.html` in your browser:

```bash
# Option 1: Direct open
open 12-group-anagrams-visualizer.html

# Option 2: Use a local server
python3 -m http.server 8000
# Then visit: http://localhost:8000/12-group-anagrams-visualizer.html
```

**What to do:**
1. Try the preset examples
2. Use "Step Through" mode to see each operation
3. Watch how the hash map builds up
4. Try your own custom inputs
5. Observe the grouping process

**Pay attention to:**
- How signatures are generated
- How words with the same signature group together
- The final grouped results

### **Step 3: Study the Code (30 minutes)**

Open `12-group-anagrams.js` and examine:

```javascript
// Start here - the main algorithm
function groupAnagrams(words) { ... }

// Compare with alternatives
function groupAnagramsCharCount(words) { ... }
function groupAnagramsPrime(words) { ... }
```

**Exercise:** Before running the code, trace through this example by hand:
```javascript
Input: ["eat", "tea", "tan"]

Step 1: Process "eat"
  - Signature: ?
  - Hash map: ?

Step 2: Process "tea"
  - Signature: ?
  - Hash map: ?

Step 3: Process "tan"
  - Signature: ?
  - Hash map: ?

Final result: ?
```

<details>
<summary>Click to see the answer</summary>

```
Step 1: Process "eat"
  - Signature: "aet"
  - Hash map: { "aet": ["eat"] }

Step 2: Process "tea"
  - Signature: "aet" (same as "eat"!)
  - Hash map: { "aet": ["eat", "tea"] }

Step 3: Process "tan"
  - Signature: "ant"
  - Hash map: { "aet": ["eat", "tea"], "ant": ["tan"] }

Final result: [["eat", "tea"], ["tan"]]
```
</details>

### **Step 4: Run the Code (15 minutes)**

Execute the implementation:

```bash
# Run the main file (includes test execution)
node 12-group-anagrams.js

# Run the test suite
node 12-group-anagrams.test.js
```

**What you'll see:**
- Multiple test cases
- Performance comparison between approaches
- Visualization of execution

### **Step 5: Test Your Understanding (20 minutes)**

Answer these questions:

**Question 1:** Why do we use sorted letters as a signature?

<details>
<summary>Answer</summary>

Because all anagrams, when sorted, produce the same string. For example:
- "eat" → "aet"
- "tea" → "aet"
- "ate" → "aet"

This gives us a unique identifier that ALL anagrams share!
</details>

**Question 2:** What is stored in the hash map?

<details>
<summary>Answer</summary>

- **Keys:** Signatures (sorted letters)
- **Values:** Arrays of words with that signature

Example: `{ "aet": ["eat", "tea", "ate"] }`
</details>

**Question 3:** Why is this faster than comparing every pair?

<details>
<summary>Answer</summary>

Comparing every pair would be O(N²):
- For 10 words: 45 comparisons
- For 100 words: 4,950 comparisons
- For 1000 words: 499,500 comparisons!

With signatures, we do O(N) operations:
- For 10 words: 10 signature generations
- For 100 words: 100 signature generations
- For 1000 words: 1000 signature generations

Much more efficient!
</details>

**Question 4:** When would you use character counting instead of sorting?

<details>
<summary>Answer</summary>

Use character counting (O(N*K) instead of O(N*K log K)) when:
- Words are very long (K is large)
- The alphabet size is small (26 letters)
- You want guaranteed O(K) instead of O(K log K) per word

The trade-off:
- Character counting: Always O(K) but more complex code
- Sorting: O(K log K) but simpler and often faster for small K
</details>

### **Step 6: Practice Variations (30 minutes)**

Try these challenges:

**Challenge 1: Case Insensitive**
```javascript
Input: ["Eat", "tea", "TAN", "ate"]
Output: [["Eat", "tea", "ate"], ["TAN"]]
```

**Challenge 2: Group Shifted Strings**
```javascript
// Strings are "shifted" if we can shift letters
// Example: "abc" → "bcd" → "cde" (shift by 1)
Input: ["abc", "bcd", "xyz", "yza"]
Output: [["abc", "bcd"], ["xyz", "yza"]]
```

**Challenge 3: Group by Length First**
```javascript
// Group by length first, then by anagram
Input: ["eat", "tea", "a", "at", "ta", "bat"]
Output: [["a"], ["at", "ta"], ["eat", "tea"], ["bat"]]
```

### **Step 7: Review & Reflect (15 minutes)**

Complete the learning by:

1. Summarizing the key pattern in your own words
2. Drawing the hash map structure on paper
3. Explaining the solution to someone else (or rubber duck!)
4. Connecting to related problems:
   - Valid Anagram (simpler version)
   - Top K Frequent Elements (similar hash map usage)
   - Longest Consecutive Sequence (hash set grouping)

---

## 🎨 Visual Learning Resources

### Recommended Medium: Animated Explainer

**Cognitive Load:** Medium
**Visual Complexity:** Medium
**Key Visual Elements:**
- Signature generation animation
- Hash map building process
- Words grouping together

**Production Time Estimate:** 4-5 hours for full animation

---

## ⚡ Quick Reference

### Time & Space Complexity

| Approach | Time | Space | Notes |
|----------|------|-------|-------|
| Sorted Signature | O(N × K log K) | O(N × K) | Most common |
| Character Count | O(N × K) | O(N × K) | Faster for long words |
| Prime Numbers | O(N × K) | O(N × K) | Can overflow |
| Naive Comparison | O(N² × K) | O(1) | Too slow! |

Where:
- **N** = number of words
- **K** = average word length

### Key Takeaways

```
┌─────────────────────────────────────────────────┐
│  PATTERN: Signature-Based Grouping              │
├─────────────────────────────────────────────────┤
│  1. Generate unique signature for each item     │
│  2. Use hash map to group by signature          │
│  3. Trade space for time efficiency             │
│  4. O(1) lookups make grouping fast             │
└─────────────────────────────────────────────────┘
```

---

## 🔗 Related Problems

**Prerequisites:**
- ← Valid Anagram (Problem #25)

**Similar Patterns:**
- → Group Shifted Strings
- → Find All Anagrams in a String
- → Top K Frequent Elements (Problem #22)

**Next Steps:**
- → Longest Consecutive Sequence (Problem #10)
- → Top K Frequent Elements (Problem #22)

---

## 💡 Common Pitfalls

### ❌ Mistake 1: Forgetting to Initialize Groups
```javascript
// WRONG - will throw error if key doesn't exist
map.get(signature).push(word);

// RIGHT - check and initialize first
if (!map.has(signature)) {
    map.set(signature, []);
}
map.get(signature).push(word);
```

### ❌ Mistake 2: Sorting the String Directly
```javascript
// WRONG - strings don't have .sort()
const signature = word.sort();

// RIGHT - convert to array first
const signature = word.split('').sort().join('');
```

### ❌ Mistake 3: Case Sensitivity Issues
```javascript
// "Eat" and "eat" have different signatures!
// Use .toLowerCase() if needed
const signature = word.toLowerCase().split('').sort().join('');
```

---

## 🎯 Assessment Checklist

Mark each item when you can do it confidently:

- [ ] Explain the problem in your own words
- [ ] Draw the hash map structure for an example
- [ ] Code the solution from memory
- [ ] Analyze time and space complexity
- [ ] Explain why hash maps are used
- [ ] Identify when to use character counting vs sorting
- [ ] Solve at least 2 variation problems
- [ ] Explain the solution to someone else

---

## 📊 Progress Tracking

**Recommended Timeline:**

| Day | Activity | Time | Status |
|-----|----------|------|--------|
| 1 | Read theory + visualizer | 1 hour | [ ] |
| 1-2 | Study code + run tests | 1 hour | [ ] |
| 2 | Practice variations | 1 hour | [ ] |
| 2-3 | Code from memory | 30 min | [ ] |
| 3 | Review + move to next | 30 min | [ ] |

**Total Time Investment:** 3-4 hours spread over 2-3 days

---

## 🚀 Real-World Applications

1. **Spell Checkers** - Group similar misspellings
2. **Search Engines** - Find pages with similar content
3. **Plagiarism Detection** - Identify rearranged text
4. **DNA Sequencing** - Group similar genetic sequences
5. **E-commerce** - Cluster products with same attributes

---

## 📖 Additional Resources

### Official Problem
- [LeetCode #49 - Group Anagrams](https://leetcode.com/problems/group-anagrams/)

### Video Explanations
- [NeetCode: Group Anagrams](https://www.youtube.com/results?search_query=neetcode+group+anagrams)
- [Back To Back SWE: Group Anagrams](https://www.youtube.com/results?search_query=back+to+back+swe+group+anagrams)

### Related Reading
- [Hash Table Time Complexity](https://stackoverflow.com/questions/9214353/hash-table-runtime-complexity-insert-search-and-delete)
- [Sorting Algorithms Overview](https://www.geeksforgeeks.org/sorting-algorithms/)

---

## 🤝 Contributing

Found an issue or want to improve this learning package?

1. Test the code thoroughly
2. Check all visualizations work
3. Verify explanations are clear
4. Submit improvements

---

## 📝 Notes Section

Use this space for your personal notes:

```
Key insights I learned:




Questions to review:




Problems I struggled with:




Real-world connections:




```

---

## 🎓 Completion Certificate

Once you've completed all steps and checked all items:

```
┌───────────────────────────────────────────────┐
│                                               │
│   🎉 CONGRATULATIONS! 🎉                      │
│                                               │
│   You have mastered:                          │
│   GROUP ANAGRAMS                              │
│                                               │
│   Phase 2: Core Patterns                      │
│   Problem #12 | Priority #8                   │
│                                               │
│   Next: Phase 2, Sub 4 - Climbing Stairs      │
│                                               │
└───────────────────────────────────────────────┘
```

---

**Built with 💜 following instructional design best practices**
**Estimated Mastery Time:** 3-4 hours
**Cognitive Load:** Medium | **Visual Complexity:** Medium

---

*Part of the DSA Training Series - 30 Essential Algorithms*
*Created: November 2025*
