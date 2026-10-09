const Test = ({ a, b }: { a: number, b: number }) => <div>Sloubi</div>

export default Test

const sloubi = {
  Testouille: (a: number, b: number) => <div>Testouille</div>
}

const [testouille, pipoup] = Promise.all([
  () => Promise.resolve("ok"),
  async () => "plop"
])

function plop(a: number, b: number) {
  console.log("Ok")
}

/**
  * Sloubi 2
  */
function sloubi2(fn: (a: number, b: number) => void) {
  console.log("sloubi2")
}

export function sloubi3() {
  sloubi2((a: number, b: number) => console.log("sloubi4"))
  console.log("sloubi3")
}
