reporting.barGraph.range = (report, barDataIndex) => {
  let maxAttributeCount = d3.max(report.rows, (attributes) => {
    const core = parseInt(attributes[barDataIndex.core], 10)
    const optional = parseInt(attributes[barDataIndex.optional], 10)
    return d3.max([optional, core])
  })

  if (maxAttributeCount % 2 !== 0) {
    maxAttributeCount++
  }

  return {
    start: 0,
    end: maxAttributeCount
  }
}
