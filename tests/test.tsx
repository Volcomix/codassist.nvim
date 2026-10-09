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
