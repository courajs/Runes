import Quick
import Fox
import Runes

private func pure<A>(a: A) -> [A] {
    return [a]
}

private func pureAppend(x: String) -> [String] {
    return pure(append(x))
}

private func purePrepend(x: String) -> [String] {
    return pure(prepend(x))
}

private func generateArray(block:[String] -> Bool) -> FOXGenerator {
    return forAll(array(string())) { array in
        return block(array as [String])
    }
}

class ArraySpec: QuickSpec {
    override func spec() {
        describe("Array") {
            describe("map") {
                // fmap id = id
                it("obeys the identity law") {
                    let property = generateArray() { array in
                        let lhs = id <^> array
                        let rhs = array

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }

                // fmap (g . h) = (fmap g) . (fmap h)
                it("obeys the function composition law") {
                    let property = generateArray() { array in
                        let lhs = compose(append, prepend) <^> array
                        let rhs = compose(curry(<^>)(append), curry(<^>)(prepend))(array)

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }
            }

            describe("apply") {
                // pure id <*> v = v
                it("obeys the identity law") {
                    let property = generateArray() { array in
                        let lhs = pure(id) <*> array
                        let rhs = array

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }

                // pure f <*> pure x = pure (f x)
                it("obeys the homomorphism law") {
                    let property = generateString() { string in
                        let lhs = pure(append) <*> pure(string)
                        let rhs = pure(append(string))

                        return rhs == lhs
                    }

                    Fox.Assert(property)
                }

                // u <*> pure y = pure ($ y) <*> u
                it("obeys the interchange law") {
                    let property = generateString() { string in
                        let lhs = pure(append) <*> pure(string)
                        let rhs = pure({ $0(string) }) <*> pure(append)

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }

                // u <*> (v <*> w) = pure (.) <*> u <*> v <*> w
                it("obeys the composition law") {
                    let property = generateArray() { array in
                        let lhs = pure(append) <*> (pure(prepend) <*> array)
                        let rhs = pure(curry(compose)) <*> pure(append)  <*> pure(prepend) <*> array

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }
            }

            describe("flatMap") {
                // return x >>= f = f x
                it("obeys the left identity law") {
                    let property = generateString() { string in
                        let lhs = pure(string) >>- pureAppend
                        let rhs = pureAppend(string)

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }

                // m >>= return = m
                it("obeys the right identity law") {
                    let property = generateArray() { array in
                        let lhs = array >>- pure
                        let rhs = array

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }

                // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
                it("obeys the associativity law") {
                    let property = generateArray() { array in
                        let lhs = (array >>- pureAppend) >>- purePrepend
                        let rhs = array >>- { x in pureAppend(x) >>- purePrepend }

                        return lhs == rhs
                    }

                    Fox.Assert(property)
                }
            }
        }
    }
}