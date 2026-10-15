lei up --all

get=$(./scripts/get.sh)
mkdir -p Documentation/_build/
rst=$(./scripts/rst.sh)

cd Documentation && make html