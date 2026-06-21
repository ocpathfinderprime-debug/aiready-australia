export function CitationScorecard({ score }: { score: { citationRate: number; cited: number; prompts: number } }) {
  return <aside>
    <h2>AI citation score</h2>
    <p>{Math.round(score.citationRate * 100)}% citation rate across {score.prompts} prompts.</p>
  </aside>;
}
