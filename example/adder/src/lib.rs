#[cfg(test)]
mod tests {

    use crate::adder;

    #[test]
    fn it_works() {
        let result = adder::add(2, 2);
        assert_eq!(result, 4);
    }
}

pub mod adder {
    #[no_mangle] 
    pub extern "C" fn add(a: i32, b: i32) -> i32 {
        a + b
    }
}
