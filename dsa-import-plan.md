# DSA Directory Import Plan

## Data Structure

### API Namespace: `algorithms`

### Fields for Algorithm Resource:

```ruby
{
  name: string,                    # "Two Sum"
  problem_number: integer,         # 24
  difficulty: string,              # "Easy", "Medium", "Hard"
  priority: integer,               # 1-30
  primary_data_structure: string,  # "Arrays, Hash Map"
  time_complexity: string,         # "O(N²) brute / O(N) optimal"
  space_complexity: string,        # "O(1) / O(N)"
  prerequisites: text,             # "None" or "Arrays basics"
  visual_complexity: string,       # "Low", "Medium", "High", "Very High"
  recommended_medium: string,      # "Static Infographic", "Animated Explainer", "Interactive Simulation"
  estimated_production_time: string, # "2-3 hours"
  key_visual_elements: text,       # "Array spotlight, Hash table visualization"
  cognitive_load: string,          # "Low", "Medium", "High"
  real_world_analogy: string,      # "Finding matching socks in a drawer"
  learning_domain: string,         # "Intellectual Skills"
  learning_phase: integer,         # 1-7

  # Instructional design fields (Gagne's 9 Events)
  problem_hook_title: string,      # "Two Sum: Find the Perfect Pair"
  problem_hook_analogy: text,      # Full analogy description
  learning_objective: text,        # What student will learn
  walkthrough_content: text,       # Algorithm explanation (rich text/markdown)
  key_insights: text,              # Important takeaways
  practice_challenge: text,        # Related problem
  related_algorithms: text,        # Links to other algorithms

  # Production tracking
  production_status: string,       # "Not Started", "In Progress", "Completed"
  visual_url: string,              # URL to hosted visual/animation
  created_at: datetime,
  updated_at: datetime
}
```

### 30 Algorithms to Import:

1. Two Sum (Problem #24, Easy, Phase 1)
2. Valid Parentheses (#26, Easy, Phase 1)
3. Move Zeroes (#19, Easy, Phase 1)
4. Valid Anagram (#25, Easy, Phase 1)
5. Best Time to Buy/Sell Stock (#3, Easy, Phase 1)
6. Container With Most Water (#8, Medium, Phase 2)
7. Product of Array Except Self (#20, Medium, Phase 2)
8. Group Anagrams (#12, Medium, Phase 2)
9. Climbing Stairs (#6, Easy, Phase 2)
10. Longest Consecutive Sequence (#15, Medium, Phase 2)
11. Daily Temperatures (#5, Medium, Phase 3)
12. Decode String (#9, Medium, Phase 3)
13. Basic Calculator (#2, Hard, Phase 3)
14. Find First and Last Position (#10, Medium, Phase 4)
15. Find Peak Element (#11, Medium, Phase 4)
16. Median of Two Sorted Arrays (#17, Hard, Phase 4)
17. Coin Change (#7, Medium, Phase 5)
18. House Robber (#13, Medium, Phase 5)
19. Word Break (#28, Medium, Phase 5)
20. Jump Game II (#14, Medium, Phase 5)
21. Add Two Numbers (#1, Medium, Phase 6)
22. Merge Intervals (#18, Medium, Phase 6)
23. LRU Cache (#16, Medium, Phase 6)
24. Top K Frequent Elements (#22, Medium, Phase 6)
25. Trapping Rain Water (#23, Hard, Phase 7)
26. Candy (#4, Hard, Phase 7)
27. Sort Colors (#21, Medium, Phase 7)
28. Valid Sudoku (#27, Medium, Phase 7)
29. Word Ladder (#29, Hard, Phase 7)
30. Word Search (#30, Medium, Phase 7)

## Learning Phases:

1. **Phase 1: Foundation Patterns** - Two Sum → Valid Parentheses → Move Zeroes → Valid Anagram → Best Time to Buy/Sell Stock
2. **Phase 2: Core Patterns** - Container With Most Water → Product of Array Except Self → Group Anagrams → Climbing Stairs → Longest Consecutive Sequence
3. **Phase 3: Stack Mastery** - Daily Temperatures → Decode String → Basic Calculator
4. **Phase 4: Binary Search** - Find First and Last Position → Find Peak Element → Median of Two Sorted Arrays
5. **Phase 5: Dynamic Programming** - Coin Change → House Robber → Word Break → Jump Game II
6. **Phase 6: Advanced Structures** - Add Two Numbers → Merge Intervals → LRU Cache → Top K Frequent
7. **Phase 7: Complex Algorithms** - Trapping Rain Water → Candy → Sort Colors → Valid Sudoku → Word Ladder → Word Search

## Implementation Steps:

1. Create API Namespace via Violet Rails admin
2. Define all fields
3. Create bulk import script or manual entry via API
4. Create custom CMS pages for:
   - Algorithm directory (filterable list)
   - Algorithm detail pages
   - Learning path tracker
5. Style with instructional design best practices
