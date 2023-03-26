import {
  Spinner,
  Box,
  Center,
  useColorModeValue,
  Text,
  Stack,
  Image,
  Flex,
  SimpleGrid,
} from '@chakra-ui/react'
import { useEffect, useState, useRef } from 'react'
import useTokenUri from '@/hooks/useTokenUri'
import useTokenId from '@/hooks/useTokenId'
import axios from 'axios'
import useTokenInfo from '@/hooks/useTokenInfo'
import Countdown from 'react-countdown'
import { zeroPad } from 'react-countdown'
import Provider from '../Providers/Provider'
import SendPact from './SendPact'
import contractAbi from '@/utils/constants/scrollBridgeAbi.json'

export default function Pact({ address, index }) {
  const [tokenId] = useTokenId(address, index, contractAbi)
  const [uri] = useTokenUri(tokenId, contractAbi)
  const [info] = useTokenInfo(tokenId, contractAbi)
  const [cid, setCid] = useState(null)
  const [image, setImage] = useState(null)
  const [stamp, setStamp] = useState(null)
  const [proposed, setProposed] = useState(null)
  useEffect(() => {
    const fetchData = () => {
      axios
        .get(uri)
        .then(function (response) {
          const image = response.data.image.replace(
            'ipfs://',
            'https://ipfs.io/ipfs/'
          )
          setImage(image)
        })
        .catch(function (error) {
          console.log(error)
        })
        .finally(function () {})
    }
    uri && fetchData()
  }, [uri])

  useEffect(() => {
    info && setStamp(Number(info[1]))
    info && setCid(info[2])
    info && setLocked(info[3])
    info && setProposed(info[5])
  }, [info])

  useEffect(() => {}, [tokenId])

  const renderer = ({ days, hours, minutes, seconds, completed }) => {
    if (completed) {
      setTimeOut(true)
      return <></>
    } else {
      return (
        <span>
          {zeroPad(hours)}:{zeroPad(minutes)}:{zeroPad(seconds)}
        </span>
      )
    }
  }
  return (
    <>
      <Center py={12}>
        <Box
          role={'group'}
          p={6}
          maxW={'330px'}
          w={'full'}
          bg={useColorModeValue('white', 'gray.800')}
          boxShadow={'2xl'}
          rounded={'lg'}
          pos={'relative'}
          zIndex={1}
        >
          <Box
            rounded={'lg'}
            mt={-12}
            pos={'relative'}
            height={'230px'}
            _after={{
              transition: 'all .3s ease',
              content: '""',
              w: 'full',
              h: 'full',
              pos: 'absolute',
              top: 5,
              left: 0,
              backgroundImage: `url(${image})`,
              filter: 'blur(15px)',
              zIndex: -1,
            }}
            _groupHover={{
              _after: {
                filter: 'blur(20px)',
              },
            }}
          >
            {image ? (
              <Image
                rounded={'lg'}
                height={230}
                width={282}
                objectFit={'cover'}
                src={image}
              />
            ) : (
              <Flex direction="column" align="center" justify="center">
                <Spinner size="xl" />
              </Flex>
            )}
          </Box>
          <Stack pt={10} align={'center'}>
            <Text
              color={'gray.500'}
              fontSize={'sm'}
              textTransform={'uppercase'}
            >
              {tokenId === null || tokenId === NaN ? '...' : `Pact #${tokenId}`}
            </Text>
            {cid && tokenId !== null && (
              <SimpleGrid columns={3} spacing={2}>
                <Provider cid={cid} tokenId={tokenId} isProposed={proposed} />
                <SendPact from={address} tokenId={tokenId} />
              </SimpleGrid>
            )}
            {stamp ? (
              <>
                <Text
                  color={'gray.500'}
                  fontSize={'m'}
                  textTransform={'uppercase'}
                >
                  <Countdown
                    date={new Date(stamp * 1000)}
                    intervalDelay={0}
                    precision={3}
                    renderer={renderer}
                  ></Countdown>
                </Text>
              </>
            ) : (
              <Text
                color={'gray.500'}
                fontSize={'m'}
                textTransform={'uppercase'}
              >
                ...
              </Text>
            )}
          </Stack>
        </Box>
      </Center>
    </>
  )
}