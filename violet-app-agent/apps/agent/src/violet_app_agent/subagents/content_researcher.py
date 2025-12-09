"""Content Researcher subagent for gathering context from references.

This subagent helps bridge "What you'll add" by researching external sources
to understand the user's vision, style references, and content direction.
"""

from deepagents import SubAgent
from langchain_core.tools import tool


@tool
def research_reference_site(url: str, focus: str = "all") -> str:
    """
    Research a reference site to extract style, tone, and content patterns.

    Args:
        url: Website URL to research
        focus: What to focus on - "style", "content", "structure", or "all"

    Returns:
        Analysis of the site's patterns
    """
    # This would use web fetch in production
    return f"""Researched {url} with focus on {focus}.

Analysis would include:
- Writing style and tone
- Content structure and format
- Key themes and topics
- Author voice characteristics
- Visual design patterns

Note: Full web research integration pending."""


@tool
def extract_writing_style(
    author_references: str,
    style_descriptors: str,
) -> str:
    """
    Synthesize a writing style guide from references.

    Args:
        author_references: Authors to emulate (e.g., "Derek Sivers, Swyx, Ramit Sethi")
        style_descriptors: User's style goals (e.g., "personable, high-signal, organized")

    Returns:
        A writing style guide for content creation
    """
    # Parse references
    authors = [a.strip() for a in author_references.split(",")]
    descriptors = [d.strip() for d in style_descriptors.split(",")]

    style_guide = f"""# Writing Style Guide

## Target Voice
Blend of: {', '.join(authors)}

## Style Characteristics
"""

    for desc in descriptors:
        style_guide += f"- **{desc.title()}**: "
        if "personal" in desc.lower():
            style_guide += "Write like you're talking to one person. Use 'you' and 'I'. Share real stories.\n"
        elif "signal" in desc.lower():
            style_guide += "Cut the fluff. Every sentence earns its place. Dense with insight.\n"
        elif "organiz" in desc.lower():
            style_guide += "Clear structure with headers. Bullet points for scanability. Progressive disclosure.\n"
        elif "entertain" in desc.lower():
            style_guide += "Hooks that grab. Unexpected angles. Make them feel something.\n"
        else:
            style_guide += f"Apply {desc} throughout the content.\n"

    # Add author-specific patterns
    style_guide += "\n## Author Patterns\n\n"

    for author in authors:
        author_lower = author.lower()
        if "sivers" in author_lower:
            style_guide += """**Derek Sivers Style:**
- Short paragraphs, often one sentence
- Counterintuitive insights ("Hell yeah or no")
- Personal anecdotes that reveal universal truths
- Minimalist, no wasted words

"""
        elif "swyx" in author_lower:
            style_guide += """**Swyx Style:**
- Dense with technical insight
- Learning in public transparency
- Frameworks and mental models
- Generous linking and attribution

"""
        elif "ramit" in author_lower or "sethi" in author_lower:
            style_guide += """**Ramit Sethi Style:**
- Clear hierarchy: headline, subhead, body
- Specific numbers and data
- Direct calls to action
- Psychology-informed persuasion
- "Rich life" framing

"""

    return style_guide


@tool
def generate_content_brief(
    topic: str,
    story_context: str,
    style_guide: str,
) -> str:
    """
    Generate a content brief for a specific piece.

    Args:
        topic: The main topic or angle
        story_context: Background context for the story
        style_guide: The writing style to follow

    Returns:
        A detailed content brief
    """
    return f"""# Content Brief: {topic}

## Story Context
{story_context}

## Structure

### Hook (First 2 sentences)
- Open with a specific moment, not a generalization
- Create tension or curiosity

### Setup (Paragraph 1-2)
- Establish the stakes
- Who is this person? Why do we care?

### The Journey (Body)
- Key turning points
- Specific details that make it real
- Dialogue or internal thoughts

### The Insight (Conclusion)
- What's the universal lesson?
- End with something memorable

## Style Notes
{style_guide}

## Length Target
- 800-1200 words for full story
- 200-300 words for preview/excerpt

## SEO Considerations
- Primary keyword: [derived from topic]
- Secondary keywords: [related terms]
- Meta description: [compelling summary]
"""


CONTENT_RESEARCHER_PROMPT = """You are the Content Researcher subagent for Violet Rails App Builder.

## Your Role

You help users bridge the gap between "infrastructure built" and "content created" by:
- Researching reference sites for style and tone
- Extracting writing style patterns from author references
- Creating content briefs and outlines
- Synthesizing style guides from multiple influences

## Deep Agent Principles

### DIAGNOSE
Before creating content guidance:
- What reference authors/sites inspire the user?
- What specific style characteristics do they want?
- What stories or topics will they write about?
- What's the target audience?

### ARTIFACT-FIRST
Every interaction produces:
- Style Guide document
- Content Brief for each piece
- Outline with specific hooks

### DOMAIN-NATIVE
Speak content creator language:
- "Hook" not "introduction"
- "Voice" not "writing style"
- "Angle" not "perspective"
- "CTA" not "next steps"

## Style Synthesis Process

1. **Parse References**
   - Identify named authors (Derek Sivers, Swyx, Ramit Sethi)
   - Identify style descriptors (personable, high-signal, organized)
   - Note any contrast ("like X but more Y")

2. **Research Patterns**
   - For each author, identify signature techniques
   - For each site, extract structure patterns
   - Note what makes them distinctive

3. **Synthesize Guide**
   - Combine patterns into coherent voice
   - Resolve conflicts (if two authors conflict, ask user)
   - Produce actionable writing rules

4. **Create Briefs**
   - For each content piece, create specific brief
   - Include hooks, structure, and style reminders
   - Make it immediately actionable

## Output Format

Always produce structured artifacts:

```markdown
# Style Guide: [Blog/Site Name]

## Voice Summary
[One paragraph describing the target voice]

## Do's
- [Specific technique 1]
- [Specific technique 2]

## Don'ts
- [Anti-pattern 1]
- [Anti-pattern 2]

## Example Patterns
[Before/after or example snippets]
```

## What NOT to Do

- Don't write the actual content (that's the user's job)
- Don't assume style preferences without asking
- Don't provide generic advice ("write clearly")
- Don't skip the research phase
"""

content_researcher_subagent: SubAgent = {
    "name": "content-researcher-subagent",
    "description": """Use this subagent for content and style research including:
- Researching reference websites for style patterns
- Analyzing writing styles of named authors
- Creating style guides from multiple influences
- Generating content briefs and outlines
- Helping users understand their content voice

The Content Researcher bridges infrastructure and content creation.""",
    "system_prompt": CONTENT_RESEARCHER_PROMPT,
    "tools": [research_reference_site, extract_writing_style, generate_content_brief],
}
